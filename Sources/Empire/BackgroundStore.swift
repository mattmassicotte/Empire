actor BackgroundStore {
	let store: Store

	public init(database: LockingDatabase) {
		self.store = Store(database: database)
	}

	public init(path: String) throws {
		let db = try LockingDatabase(path: path)

		self.init(database: db)
	}

#if compiler(>=6.1)
	public func withTransaction<T>(
		_ block: (TransactionContext) throws -> sending T
	) throws -> sending T {
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

struct BackgroundableStore: Sendable {
	let mainStore: MainActorStore
	public let background: BackgroundStore

	@MainActor
	public init(database: LockingDatabase) {
		self.mainStore = MainActorStore(database: database)
		self.background = BackgroundStore(database: database)
	}

	@MainActor
	public var main: Store {
		mainStore.store
	}
}
