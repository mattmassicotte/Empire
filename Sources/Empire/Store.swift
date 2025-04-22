import LMDB
import CLMDB
import PackedSerialize

public enum StoreError: Error, Hashable {
	case noActiveContext
	case noActiveStore
	case keyBufferOverflow
	case valueBufferOverflow
	case recordPrefixMismatch(String, Int, Int)
	case migrationUnsupported(String, Int, Int)
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

/// Interface to Empire database.
public final class Store {
	private static let minimumFieldBufferSize = 1024 * 32
	
	private let environment: Environment
	private var dbi = [String: MDB_dbi]()
	private var keyBuffer: UnsafeMutableRawBufferPointer
	private var valueBuffer: UnsafeMutableRawBufferPointer

	/// Create an instance with a path to the on-disk database file.
	public init(path: String) throws {
		self.environment = try Environment(path: path, maxDatabases: 1)
		self.keyBuffer = UnsafeMutableRawBufferPointer.allocate(
			byteCount: environment.maximumKeySize,
			alignment: MemoryLayout<UInt8>.alignment
		)
		self.valueBuffer = UnsafeMutableRawBufferPointer.allocate(
			byteCount: Self.minimumFieldBufferSize,
			alignment: MemoryLayout<UInt8>.alignment
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
	
#if compiler(>=6.1)
	/// Execute a transation on a database.
	public func withTransaction<T>(
		_ block: (TransactionContext) throws -> sending T
	) throws -> sending T {
		let value = try Transaction.with(env: environment) { txn in
			let dbi = try activeDBI(for: "mydb", txn)

			let context = TransactionContext(
				transaction: txn,
				dbi: dbi,
				keyBuffer: keyBuffer,
				valueBuffer: valueBuffer
			)

			return try block(context)
		}

		return value
	}
#else
	/// Execute a transation on a database.
	public func withTransaction<T : Sendable>(
		_ block: (TransactionContext) throws -> sending T
	) throws -> sending T {
		let value = try Transaction.with(env: environment) { txn in
			let dbi = try activeDBI(for: "mydb", txn)

			let context = TransactionContext(
				transaction: txn,
				dbi: dbi,
				keyBuffer: keyBuffer,
				valueBuffer: valueBuffer
			)

			return try block(context)
		}

		return value
	}
#endif
}

#if canImport(Foundation)
import Foundation

extension Store {
	/// Create an instance with a URL to the on-disk database file.
	public convenience init(url: URL) throws {
		try self.init(path: url.path)
	}
}
#endif
