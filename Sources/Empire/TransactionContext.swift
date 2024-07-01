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
	public func select<Record: IndexKeyRecord>(key: some Serializable) throws -> sending Record? {
		let keyVal = try MDB_val(key, using: keyBuffer)

		guard let valueVal = try transaction.get(dbi: dbi, key: keyVal) else {
			return nil
		}

		var localBuffer = DeserializationBuffer(key: keyVal, value: valueVal)

		return try Record(&localBuffer)
	}

	// This should not need the `where Record: Sendable`...
	// https://github.com/swiftlang/swift/issues/74845
	public func select<Record: IndexKeyRecord, each Component: QueryComponent, Last: QueryComponent>(
		query: Query<repeat each Component, Last>
	) throws -> sending [Record] where Record: Sendable {
		switch query.last {
		case let .equals(value):
			let key = Tuple(repeat each query.components, value)
			if let record: Record = try select(key: key) {
				return [record]
			}
		case let .greaterThan(value):
			let key = Tuple(repeat each query.components, value)
			let keyVal = try MDB_val(key, using: keyBuffer)
			let query = Cursor.Query(key: keyVal, forward: true)

			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: query)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
			}
		case let .greaterOrEqual(value):
			let key = Tuple(repeat each query.components, value)
			let keyVal = try MDB_val(key, using: keyBuffer)
			let query = Cursor.Query(key: keyVal, forward: true)

			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: query)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
			}
		case let .range(range):
			let key = Tuple(repeat each query.components, range.lowerBound)
			let keyVal = try MDB_val(key, using: keyBuffer)
			let endKey = Tuple(repeat each query.components, range.upperBound)
			let endKeyVal = try MDB_val(endKey, using: valueBuffer)

			let query = Cursor.Query(key: keyVal, forward: true, endKey: endKeyVal, inclusive: false)

			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: query)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
			}
		case let .closedRange(range):
			let key = Tuple(repeat each query.components, range.lowerBound)
			let keyVal = try MDB_val(key, using: keyBuffer)
			let endKey = Tuple(repeat each query.components, range.upperBound)
			let endKeyVal = try MDB_val(endKey, using: valueBuffer)

			let query = Cursor.Query(key: keyVal, forward: true, endKey: endKeyVal, inclusive: true)

			let cursor = try Cursor(transaction: transaction, dbi: dbi, query: query)

			return try cursor.map { pair in
				var localBuffer = DeserializationBuffer(key: pair.0, value: pair.1)

				return try Record(&localBuffer)
			}
		default:
			fatalError("not yet")
		}

		return []
	}
}

extension TransactionContext {
	public func delete<Record: IndexKeyRecord>(_ record: Record) throws {
		// TODO: this could be optmized to just find the key
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
