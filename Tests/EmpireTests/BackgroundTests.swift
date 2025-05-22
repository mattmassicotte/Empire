import Foundation
import Testing

import Empire

@IndexKeyRecord("key")
fileprivate struct BackgroundKeyOnlyRecord: Hashable {
	let key: Int
}

@Suite(.serialized)
struct BackgroundTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/empire_background_store", isDirectory: true)

	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)
	}

	@Test func writeInBackground() async throws {
		let database = try LockingDatabase(url: Self.storeURL)

		let store = BackgroundStore(database: database)

		try await withThrowingTaskGroup(of: Void.self) { group in
			for i in 0..<50 {
				group.addTask {
					try await store.withTransaction { ctx in
						try BackgroundKeyOnlyRecord(key: i).insert(in: ctx)
					}
				}
			}

			try await group.waitForAll()
		}

		let records = try await store.withTransaction { ctx in
			try BackgroundKeyOnlyRecord.select(in: ctx, key: .greaterOrEqual(0))
		}

		#expect(records.count == 50)
	}

	@MainActor
	@Test func writeOnMainReadInBackground() async throws {
		let database = try LockingDatabase(url: Self.storeURL)

		let store = BackgroundableStore(database: database)

		let readTask = Task<Void, Error> {
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<50 {
					group.addTask {
						_ = try await store.background.withTransaction { ctx in
							try BackgroundKeyOnlyRecord.select(in: ctx, key: .greaterOrEqual(0))
						}
					}
				}

				try await group.waitForAll()
			}
		}

		try store.main.withTransaction { ctx in
			try BackgroundKeyOnlyRecord(key: 42).insert(in: ctx)
		}

		try await readTask.value
	}

	@Test func transactionCancellation() async throws {
		let database = try LockingDatabase(url: Self.storeURL)

		let store = BackgroundStore(database: database)

		let task = Task {
			// slow this task down a little so don't finish before cancelling
			try await Task.sleep(for: .milliseconds(50))

			try await store.withTransaction { ctx in
				for i in 0..<50 {
					try BackgroundKeyOnlyRecord(key: i).insert(in: ctx)
				}
			}
		}

		task.cancel()
		await #expect(throws: CancellationError.self, performing: {
			try await task.value
		})

		let records = try await store.withTransaction { ctx in
			try BackgroundKeyOnlyRecord.select(in: ctx, key: .greaterOrEqual(0))
		}

		#expect(records.count == 0)
	}
}
