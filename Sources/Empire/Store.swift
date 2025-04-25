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

/// Represents the on-disk storage.
public struct Database: Sendable {
	let environment: Environment
	let dbi: MDB_dbi
	
	/// Create an instance with a path to the on-disk database file.
	///
	/// If there is no file at the specified path, one will be created.
	public init(path: String) throws {
		self.environment = try Environment(
			path: path,
			maxDatabases: 1,
			locking: true
		)
		
		self.dbi = try Transaction.with(env: environment) { txn in
			try txn.open(name: "empiredb")
		}
	}
}

/// Interface to Empire database.
///
/// The `Store` is the main interface to a single database file.
public final class Store {
	private static let minimumFieldBufferSize = 1024 * 32
	
	private let database: Database
	private let buffer: SerializationBuffer

	/// Create an instance with a path to the on-disk database file.
	///
	/// If there is no file at the specified path, one will be created.
	public init(database: Database) {
		self.database = database
		self.buffer = SerializationBuffer(
			keySize: database.environment.maximumKeySize,
			valueSize: Self.minimumFieldBufferSize
		)
	}
		
	public convenience init(path: String) throws {
		let db = try Database(path: path)
		
		self.init(database: db)
	}
	
#if compiler(>=6.1)
	/// Execute a transation on a database.
	public func withTransaction<T>(
		_ block: (TransactionContext) throws -> sending T
	) throws -> sending T {
		let value = try Transaction.with(env: database.environment) { txn in
			let context = TransactionContext(
				transaction: txn,
				dbi: database.dbi,
				buffer: buffer
			)

			return try block(context)
		}

		return value
	}
#else
	/// Execute a transation on a database.
	public func withTransaction<T: Sendable>(
		_ block: (TransactionContext) throws -> sending T
	) throws -> sending T {
		let value = try Transaction.with(env: database.environment) { txn in
			let context = TransactionContext(
				transaction: txn,
				dbi: database.dbi,
				buffer: buffer
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
	///
	/// If there is no file at the specified url, one will be created.
	public convenience init(url: URL) throws {
		try self.init(path: url.path)
	}
}
#endif
