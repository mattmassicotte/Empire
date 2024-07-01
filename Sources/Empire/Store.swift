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
