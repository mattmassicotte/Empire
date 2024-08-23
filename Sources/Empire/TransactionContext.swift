import CLMDB
import LMDB

public struct TransactionContext {
	var transaction: Transaction
	let dbi: MDB_dbi
	let keyBuffer: UnsafeMutableRawBufferPointer
	let valueBuffer: UnsafeMutableRawBufferPointer
}

extension TransactionContext {
	public func insert<Record: IndexKeyRecord>(_ record: Record) throws {
		let keySize = record.indexKeySerializedSize
		guard keySize <= keyBuffer.count else {
			throw StoreError.keyBufferOverflow
		}

		let valueSize = record.fieldsSerializedSize
		guard valueSize <= valueBuffer.count else {
			throw StoreError.valueBufferOverflow
		}

		var localBuffer = SerializationBuffer(keyBuffer: keyBuffer, valueBuffer: valueBuffer)

		record.serialize(into: &localBuffer)

		let keyData = UnsafeRawBufferPointer(start: keyBuffer.baseAddress, count: keySize)
		let fieldsData = UnsafeRawBufferPointer(start: valueBuffer.baseAddress, count: valueSize)

		try transaction.set(dbi: dbi, keyBuffer: keyData, valueBuffer: fieldsData)
	}
}

extension TransactionContext {
	public func select<Record: IndexKeyRecord>(key: some Serializable) throws -> Record? {
		let keyVal = try MDB_val(key, using: keyBuffer)

		guard let valueVal = try transaction.get(dbi: dbi, key: keyVal) else {
			return nil
		}

		var localBuffer = DeserializationBuffer(key: keyVal, value: valueVal)

		return try Record(&localBuffer)
	}

	/// Perform a select and copy the resulting data into a new Record.
	///
	/// This version is useful if the underlying IndexKeyRecord is not Sendable but you want to transfer it out of a transaction context.
	public func selectCopy<Record: IndexKeyRecord>(key: some Serializable) throws -> sending Record? {
		let keyVal = try MDB_val(key, using: keyBuffer)

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

				return try Record(&localBuffer)
			}
		}
	}

	// I think this can be further improved with a copying version. But, that may also be affected by:
	// https://github.com/swiftlang/swift/issues/74845
	public func select<Record: IndexKeyRecord, each Component: QueryComponent, Last: QueryComponent>(
		query: Query<repeat each Component, Last>
	) throws -> sending [Record] where Record: Sendable {
		let bufferPair = SerializationBuffer(keyBuffer: keyBuffer, valueBuffer: valueBuffer)

		switch query.last {
		case let .equals(value):
			let key = Tuple(repeat each query.components, value)
			if let record: Record = try select(key: key) {
				return [record]
			}
		case .greaterThan:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
			}
		case .greaterOrEqual:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
			}
		case .lessThan:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
			}
		case .lessOrEqual:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
			}
		case .range:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
			}
		case .closedRange:
			let lmdbQuery = try query.buildLMDDBQuery(buffer: bufferPair)
			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: lmdbQuery)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
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

		return []
	}
}

extension TransactionContext {
	public func delete<Record: IndexKeyRecord>(_ record: Record) throws {
		// TODO: this could be optimized to just find the key
		let keySize = record.indexKeySerializedSize
		guard keySize <= keyBuffer.count else {
			throw StoreError.keyBufferOverflow
		}

		let valueSize = record.fieldsSerializedSize
		guard valueSize <= valueBuffer.count else {
			throw StoreError.valueBufferOverflow
		}

		var localBuffer = SerializationBuffer(keyBuffer: keyBuffer, valueBuffer: valueBuffer)

		record.serialize(into: &localBuffer)

		let key = MDB_val(mv_size: keySize, mv_data: keyBuffer.baseAddress)

		try transaction.delete(dbi: dbi, key: key)
	}
}
