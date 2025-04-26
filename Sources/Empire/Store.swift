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

/// Represents the on-disk storage that supports concurrent accesses.
public struct LockingDatabase: Sendable {
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

/// Represents the on-disk storage.
public struct Database {
	let environment: Environment
	let dbi: MDB_dbi
	
	/// Create an instance with a path to the on-disk database file.
	///
	/// If there is no file at the specified path, one will be created.
	public init(path: String) throws {
		self.environment = try Environment(
			path: path,
			maxDatabases: 1,
			locking: false
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
	
	private let environment: Environment
	private let dbi: MDB_dbi
	private let buffer: SerializationBuffer

	init(environment: Environment, dbi: MDB_dbi) {
		self.environment = environment
		self.dbi = dbi
		self.buffer = SerializationBuffer(
			keySize: environment.maximumKeySize,
			valueSize: Self.minimumFieldBufferSize
		)

	}
	
	/// Create an instance with a path to the on-disk database file.
	///
	/// If there is no file at the specified path, one will be created.
	public convenience init(database: Database) {
		self.init(environment: database.environment, dbi: database.dbi)
	}
	
	/// Create an instance with a path to the on-disk database file.
	///
	/// If there is no file at the specified path, one will be created.
	public convenience init(database: LockingDatabase) {
		self.init(environment: database.environment, dbi: database.dbi)
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
		let value = try Transaction.with(env: environment) { txn in
			let context = TransactionContext(
				transaction: txn,
				dbi: dbi,
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
		let value = try Transaction.with(env: environment) { txn in
			let context = TransactionContext(
				transaction: txn,
				dbi: dbi,
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

extension Database {
	public init(url: URL) throws {
		try self.init(path: url.path)
	}
}

extension LockingDatabase {
	public init(url: URL) throws {
		try self.init(path: url.path)
	}
}
#endif
