import CLMDB
import LMDB

/// Represents a database transaction.
///
/// Transactions have full ACID sematics.
public struct TransactionContext {
	var transaction: Transaction
	let dbi: MDB_dbi
	let buffer: SerializationBuffer
	
	init(transaction: Transaction, dbi: MDB_dbi, buffer: SerializationBuffer) {
		self.transaction = transaction
		self.dbi = dbi
		self.buffer = buffer
	}
}

extension TransactionContext {
	public func insert<Record: IndexKeyRecord>(_ record: Record) throws {
		let prefix = Record.keyPrefix
		let version = Record.fieldsVersion

		let keySize = record.indexKey.serializedSize + prefix.serializedSize
		guard keySize <= buffer.keyBuffer.count else {
			throw StoreError.keyBufferOverflow
		}

		let valueSize = record.fields.serializedSize + version.serializedSize
		guard valueSize <= buffer.valueBuffer.count else {
			throw StoreError.valueBufferOverflow
		}

		var localBuffer = self.buffer

		prefix.serialize(into: &localBuffer.keyBuffer)
		version.serialize(into: &localBuffer.valueBuffer)

		record.serialize(into: &localBuffer)

		let keyData = UnsafeRawBufferPointer(start: buffer.keyBuffer.baseAddress, count: keySize)
		let fieldsData = UnsafeRawBufferPointer(start: buffer.valueBuffer.baseAddress, count: valueSize)

		try transaction.set(dbi: dbi, keyBuffer: keyData, valueBuffer: fieldsData)
	}
}

extension TransactionContext {
	enum DeserializationResult<Record: IndexKeyRecord> {
		case success(Record)
		case migrated(Record)
		case prefixMismatch(IndexKeyRecordHash)
		
		var record: Record? {
			switch self {
			case let .success(value), let .migrated(value):
				return value
			case .prefixMismatch:
				return nil
			}
		}
		
		var recordIfMatching: Record {
			get throws {
				switch self {
				case let .success(value), let .migrated(value):
					return value
				case let .prefixMismatch(readPrefix):
					throw StoreError.recordPrefixMismatch(String(describing: Record.self), Record.keyPrefix, readPrefix)
				}
			}
		}
	}
	
	private func deserialize<Record: IndexKeyRecord>(
		keyValue: MDB_val,
		buffer: inout DeserializationBuffer
	) throws -> DeserializationResult<Record> {
		let prefix = Record.keyPrefix

		let readPrefix = try IndexKeyRecordHash(buffer: &buffer.keyBuffer)
		if prefix != readPrefix {
			return .prefixMismatch(readPrefix)
		}

		let version = try IndexKeyRecordHash(buffer: &buffer.valueBuffer)
		if version != Record.fieldsVersion {
			// create the new migrated record
			let newRecord = try Record(&buffer, version: version)

			// delete the existing record
			try transaction.delete(dbi: dbi, key: keyValue)

			// insert the new one
			try insert(newRecord)

			return .migrated(newRecord)
		}

		let record = try Record(&buffer)
		
		return .success(record)
	}
}

extension TransactionContext {
	public func select<Record: IndexKeyRecord>(key: some Serializable) throws -> Record? {
		let prefix = Record.keyPrefix

		let keyVal = try MDB_val(key, prefix: prefix, using: buffer.keyBuffer)

		guard let valueVal = try transaction.get(dbi: dbi, key: keyVal) else {
			return nil
		}

		var localBuffer = DeserializationBuffer(key: keyVal, value: valueVal)

		return try deserialize(keyValue: keyVal, buffer: &localBuffer).recordIfMatching
	}

	/// Perform a select and copy the resulting data into a new Record.
	///
	/// This version is useful if the underlying IndexKeyRecord is not Sendable but you want to transfer it out of a transaction context.
	public func selectCopy<Record: IndexKeyRecord>(key: some Serializable) throws -> sending Record? {
		let prefix = Record.keyPrefix
		let keyVal = try MDB_val(key, prefix: prefix, using: buffer.keyBuffer)

		guard let valueVal = try transaction.get(dbi: dbi, key: keyVal) else {
			return nil
		}

		let keyData = keyVal.bufferPointer.copyToByteArray()
		let valueData = valueVal.bufferPointer.copyToByteArray()

		return try keyData.withUnsafeBufferPointer { keyBuffer in
			try valueData.withUnsafeBufferPointer { valueBuffer in
				var localBuffer = DeserializationBuffer(
					keyBuffer: UnsafeRawBufferPointer(keyBuffer),
					valueBuffer: UnsafeRawBufferPointer(valueBuffer)
				)

				let readPrefix = try IndexKeyRecordHash(buffer: &localBuffer.keyBuffer)
				if prefix != readPrefix {
					throw StoreError.recordPrefixMismatch(String(describing: Record.self), prefix, readPrefix)
				}

				let version = try IndexKeyRecordHash(buffer: &localBuffer.valueBuffer)
				if version != Record.fieldsVersion {
					throw StoreError.migrationUnsupported(String(describing: Record.self), Record.fieldsVersion, version)
				}

				return try Record(&localBuffer)
			}
		}
	}

	// I think this can be further improved with a copying version. But, that may also be affected by:
	// https://github.com/swiftlang/swift/issues/74845
	public func select<Record: IndexKeyRecord, each Component: QueryComponent, Last: QueryComponent>(
		query: Query<repeat each Component, Last>
	) throws -> sending [Record] where Record: Sendable {
		let prefix = Record.keyPrefix
		let bufferPair = self.buffer

		switch query.last {
		case .greaterThan, .greaterOrEqual, .lessThan, .lessOrEqual:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair, prefix: prefix)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			var records: [Record] = []
			
			for pair in cursor {
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				let result: DeserializationResult<Record> = try deserialize(keyValue: pair.0, buffer: &localBuffer)
				
				switch result {
				case let .migrated(record), let .success(record):
					records.append(record)
				case .prefixMismatch:
					return records
				}
			}
			
			return records
		case .range:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair, prefix: prefix)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try deserialize(keyValue: pair.0, buffer: &localBuffer).recordIfMatching
			}
		case .closedRange:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair, prefix: prefix)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try deserialize(keyValue: pair.0, buffer: &localBuffer).recordIfMatching
			}
		case let .within(values):
			return try values.map { value in
				let key = Tuple(repeat each query.components, value)

				guard let record: Record = try select(key: key) else {
					throw MDBError.recordNotFound
				}

				return record
			}
		}
	}
}

extension TransactionContext {
	private func delete(prefix: Int, key: some Serializable) throws {
		let keyVal = try MDB_val(key, prefix: prefix, using: buffer.keyBuffer)

		try transaction.delete(dbi: dbi, key: keyVal)
	}

	/// Delete this record using its `indexKey` property.
	public func delete<Record: IndexKeyRecord>(_ record: Record) throws {
		try delete(recordType: Record.self, key: record.indexKey)
	}

	/// Delete a record type using its IndexKey.
	public func delete<Record: IndexKeyRecord>(recordType: Record.Type, key: Record.IndexKey) throws {
		let keyVal = try MDB_val(key, prefix: recordType.keyPrefix, using: buffer.keyBuffer)

		try transaction.delete(dbi: dbi, key: keyVal)
	}
}
