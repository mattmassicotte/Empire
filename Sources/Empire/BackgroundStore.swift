/// Asynchronous interface to an Empire database that executes transactions on non-main threads.
public actor BackgroundStore {
	let store: Store

	public init(database: LockingDatabase) {
		self.store = Store(database: database)
	}

	public init(path: String) throws {
		let db = try LockingDatabase(path: path)

		self.init(database: db)
	}

#if compiler(>=6.1)
	/// Execute a transation on a database.
	public func withTransaction<T>(
		_ block: sending (TransactionContext) throws -> sending T
	) throws -> sending T {
		try store.withTransaction { ctx in
			try block(ctx)
		}
	}
#else
	/// Execute a transation on a database.
	public func withTransaction<T: Sendable>(
		_ block: sending (TransactionContext) throws -> sending T
	) throws -> T {
		try store.withTransaction { ctx in
			try block(ctx)
		}
	}
#endif
}

@MainActor
struct MainActorStore {
	let store: Store

	init(database: LockingDatabase) {
		self.store = Store(database: database)
	}
}

/// An interface to an Empire database that supports both synchronous and asynchronous accesses.
public final class BackgroundableStore: Sendable {
	let mainStore: MainActorStore
	/// A `Store` instance that executes transactions on non-main threads.
	public let background: BackgroundStore

	@MainActor
	public init(database: LockingDatabase) {
		self.mainStore = MainActorStore(database: database)
		self.background = BackgroundStore(database: database)
	}

	@MainActor
	convenience init(path: String) throws {
		let db = try LockingDatabase(path: path)

		self.init(database: db)
	}

	/// A `Store` instance that executes transactions on the `MainActor`.
	@MainActor
	public var main: Store {
		mainStore.store
	}
}

#if canImport(Foundation)
import Foundation

extension BackgroundableStore {
	@MainActor
	public convenience init(url: URL) throws {
		let db = try LockingDatabase(url: url)

		self.init(database: db)
	}
}
#endif
