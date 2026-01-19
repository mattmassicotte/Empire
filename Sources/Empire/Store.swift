import LMDB
import CLMDB
import PackedSerialize

public enum StoreError: Error, Hashable {
	case noActiveContext
	case noActiveStore
	case keyBufferOverflow
	case valueBufferOverflow
	case recordPrefixMismatch(String, IndexKeyRecordHash, IndexKeyRecordHash)
	case migrationUnsupported(String, IndexKeyRecordHash, IndexKeyRecordHash)
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

/// Interface to an Empire database.
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
		parent: TransactionContext? = nil,
		readOnly: Bool = false,
		_ block: (TransactionContext) throws -> sending T
	) throws -> sending T {
		let value = try Transaction.with(env: environment, parent: parent?.transaction, readOnly: readOnly) { txn in
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
	) throws -> T {
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

extension Store {
	/// Insert a single record into the store.
	public func insert<Record: IndexKeyRecord>(_ record: Record) throws {
		try withTransaction { ctx in
			try ctx.insert(record)
		}
	}
	
#if compiler(>=6.1)
	/// Retrieve a single record from the store.
	///
	/// This is currently implemented with a `selectCopy` internally.
	public func select<Record: IndexKeyRecord>(
		key: Record.IndexKey
	) throws -> sending Record? {
		try withTransaction { ctx in
			// this must be a copy to work around sending the result
			try ctx.select(key: key)
		}
	}
#else
	/// Retrieve a single record from the store.
	public func select<Record: IndexKeyRecord>(
		key: Record.IndexKey
	) throws -> Record? where Record: Sendable {
		try withTransaction { ctx in
			// this must be a copy to work around sending the result
			try ctx.select(key: key)
		}
	}
#endif
	
	/// Delete a single record from the store.
	public func delete<Record: IndexKeyRecord>(_ record: Record) throws {
		try withTransaction { ctx in
			try ctx.delete(record)
		}
	}
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
