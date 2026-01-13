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

	private func deserializeSpan<Record: IndexKeyRecord>(
		keyValue: MDB_val,
		buffer: inout DeserializationBuffer
	) throws -> sending DeserializationResult<Record> {
		let prefix = Record.keyPrefix
		var keyDeserializer = Deserializer(span: keyValue.span)

		let readPrefix = try IndexKeyRecordHash.unpack(with: &keyDeserializer)
		if prefix != readPrefix {
			throw StoreError.recordPrefixMismatch(String(describing: Record.self), prefix, readPrefix)
		}

		var valueDeserializer = Deserializer(_unsafeBytes: buffer.valueBuffer)
		let version = try IndexKeyRecordHash.unpack(with: &valueDeserializer)
		let deserializer = RecordDeserializer(keyDeserializer: keyDeserializer, fieldsDeserializer: valueDeserializer)
		if version != Record.fieldsVersion {
			// create the new migrated record

			nonisolated(unsafe) let newRecord = try Record.deserialize(with: deserializer, version: version)

			// delete the existing record
			try transaction.delete(dbi: dbi, key: keyValue)

			// insert the new one, in a way that does not hold onto newRecord in any way
			try insert(newRecord)

			return .migrated(newRecord)
		}

		return .success(try Record.deserialize(with: deserializer))
	}
}

extension TransactionContext {
	public func select<Record: IndexKeyRecord>(key: some Serializable) throws -> sending Record? {
		let prefix = Record.keyPrefix

		let keyVal = try MDB_val(key, prefix: prefix, using: buffer.keyBuffer)

		guard let valueVal = try transaction.get(dbi: dbi, key: keyVal) else {
			return nil
		}

		var localBuffer = DeserializationBuffer(key: keyVal, value: valueVal)

		return try deserializeSpan(keyValue: keyVal, buffer: &localBuffer).recordIfMatching
	}

	@available(*, deprecated, message: "This is no longer necessary, please use select directly instead.")
	public func selectCopy<Record: IndexKeyRecord>(key: some Serializable) throws -> sending Record? {
		try select(key: key)
	}

	// I think this can be further improved with a copying version. But, that may also be affected by:
	// https://github.com/swiftlang/swift/issues/74845
	public func select<Record: IndexKeyRecord, each Component: QueryComponent, Last: QueryComponent>(
		query: Query<repeat each Component, Last>
	) throws -> sending [Record] {
		let prefix = Record.keyPrefix
		let bufferPair = self.buffer

		switch query.last {
		case .greaterThan, .greaterOrEqual, .lessThan, .lessOrEqual:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair, prefix: prefix)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			var records: [Record] = []
			
			for pair in cursor {
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				let result: DeserializationResult<Record> = try deserializeSpan(keyValue: pair.0, buffer: &localBuffer)

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

			return try cursor.sendingMap { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try deserializeSpan(keyValue: pair.0, buffer: &localBuffer).recordIfMatching
			}
		case .closedRange:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair, prefix: prefix)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			return try cursor.sendingMap { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try deserializeSpan(keyValue: pair.0, buffer: &localBuffer).recordIfMatching
			}
		case let .within(values):
			return try values.sendingMap { value in
				let key = Tuple(repeat each query.components, value)

				guard let record: Record = try select(key: key) else {
					throw MDBError.recordNotFound
				}

				return record
			}
		}
	}
}

extension Sequence {
	func sendingMap<T, E>(_ transform: (Self.Element) throws(E) -> sending T) throws(E) -> sending [T] where E : Error {
		var newValue = [T]()

		for value in self {
			try newValue.append(transform(value))
		}

		return newValue
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
