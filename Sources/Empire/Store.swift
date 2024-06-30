import LMDB
import CLMDB
import PackedSerialize

enum StoreError: Error {
	case noActiveContext
	case noActiveStore
	case keyBufferOverflow
	case valueBufferOverflow
}

public struct SerializationBuffer {
	public var keyBuffer: UnsafeMutableRawBufferPointer
	public var valueBuffer: UnsafeMutableRawBufferPointer
}

public struct DeserializationBuffer {
	public var keyBuffer: UnsafeRawBufferPointer
	public var valueBuffer: UnsafeRawBufferPointer

	init(keyBuffer: UnsafeRawBufferPointer, valueBuffer: UnsafeRawBufferPointer) {
		self.keyBuffer = keyBuffer
		self.valueBuffer = valueBuffer
	}

	init(key: MDB_val, value: MDB_val) {
		self.keyBuffer = key.bufferPointer
		self.valueBuffer = value.bufferPointer
	}
}

public struct TransactionContext {
	var transaction: Transaction
	let dbi: MDB_dbi
	let keyBuffer: UnsafeMutableRawBufferPointer
	let valueBuffer: UnsafeMutableRawBufferPointer

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

public actor Store {
	@TaskLocal private nonisolated static var taskStore: Store?

	private var environment: Environment
	private var dbi = [String: MDB_dbi]()
	private var keyBuffer: UnsafeMutableRawBufferPointer
	private var valueBuffer: UnsafeMutableRawBufferPointer

	public init(path: String) throws {
		self.environment = try Environment(path: path, maxDatabases: 1)
		self.keyBuffer = UnsafeMutableRawBufferPointer.allocate(
			byteCount: environment.maximumKeySize,
			alignment: MemoryLayout<Int>.alignment
		)
		self.valueBuffer = UnsafeMutableRawBufferPointer.allocate(
			byteCount: 1024,
			alignment: MemoryLayout<Int>.alignment
		)
	}

	private func activeDBI(for name: String, _ transaction: Transaction) throws -> MDB_dbi {
		if let value = dbi[name] {
			return value
		}

		let value = try transaction.open(name: name)

		self.dbi[name] = value

		return value
	}

	public func withTransaction<T>(_ block: sending (TransactionContext) throws -> sending T) async throws -> sending T {
		return try Transaction.with(env: environment) { txn in
			let dbi = try activeDBI(for: "mydb", txn)

			let context = TransactionContext(
				transaction: txn,
				dbi: dbi,
				keyBuffer: keyBuffer,
				valueBuffer: valueBuffer
			)

			return try block(context)
		}
	}
}

#if canImport(Foundation)
import Foundation

extension Store {
	public init(url: URL) throws {
		try self.init(path: url.path)
	}
}
#endif
