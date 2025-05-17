import Foundation
import Testing

import LMDB

@Suite(.serialized)
struct LMDBTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/store", isDirectory: true)

	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)
	}

	@Test func testWriteKey() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "hello", value: "goodbye")
			let value = try txn.getString(dbi: dbi, key: "hello")

			#expect(value == "goodbye")
		}
	}

	@Test func testWriteKeyCloseAndRead() throws {
		// Scope has to be more carefully controlled here, to ensure the database is deallocated (closed) correctly
		do {
			let env = try Environment(url: Self.storeURL, maxDatabases: 1)
			
			try Transaction.with(env: env) { txn in
				let dbi = try txn.open(name: "mydb")
				
				try txn.set(dbi: dbi, key: "hello", value: "goodbye")
			}
		}

		do {
			let env = try Environment(url: Self.storeURL, maxDatabases: 1)
			
			try Transaction.with(env: env) { txn in
				let dbi = try txn.open(name: "mydb")
				
				let value = try txn.getString(dbi: dbi, key: "hello")
				
				#expect(value == "goodbye")
			}
		}
	}

	@Test func testMissingKey() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			#expect(try txn.getString(dbi: dbi, key: "hello") == nil)
		}
	}

	@Test func deleteKey() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "hello", value: "goodbye")
			let value = try txn.getString(dbi: dbi, key: "hello")

			#expect(value == "goodbye")

			try txn.delete(dbi: dbi, key: "hello")

			#expect(try txn.getString(dbi: dbi, key: "hello") == nil)
		}
	}

	@Test func deleteMissingKey() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			#expect(throws: MDBError.recordNotFound) {
				try txn.delete(dbi: dbi, key: "hello")
			}
		}
	}
}

extension LMDBTests {
	@Test func greaterOrEqual() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "c", value: "3")
			try txn.set(dbi: dbi, key: "a", value: "1")
			try txn.set(dbi: dbi, key: "b", value: "2")

			try "a".withMDBVal { searchKey in
				let query = Query(comparison: .greaterOrEqual(searchKey))
				let cursor = try Cursor(transaction: txn, dbi: dbi, query: query)

				let values: [(String, String)] = cursor.compactMap {
					guard
						let key = String(mdbVal: $0.0),
						let value = String(mdbVal: $0.1)
					else {
						return nil
					}

					return (key, value)
				}

				try #require(values.count == 3)
				#expect(values[0] == ("a", "1"))
				#expect(values[1] == ("b", "2"))
				#expect(values[2] == ("c", "3"))
			}
		}
	}
	
	@Test func greater() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "c", value: "3")
			try txn.set(dbi: dbi, key: "b", value: "2")

			try "a".withMDBVal { searchKey in
				let query = Query(comparison: .greater(searchKey))
				let cursor = try Cursor(transaction: txn, dbi: dbi, query: query)

				let values: [(String, String)] = cursor.compactMap {
					guard
						let key = String(mdbVal: $0.0),
						let value = String(mdbVal: $0.1)
					else {
						return nil
					}

					return (key, value)
				}

				try #require(values.count == 2)
				#expect(values[0] == ("b", "2"))
				#expect(values[1] == ("c", "3"))
			}
		}
	}


	@Test func greaterOrEqualWithLimit() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "c", value: "3")
			try txn.set(dbi: dbi, key: "a", value: "1")
			try txn.set(dbi: dbi, key: "b", value: "2")

			try "a".withMDBVal { searchKey in
				let query = Query(comparison: .greaterOrEqual(searchKey), limit: 2)
				let cursor = try Cursor(transaction: txn, dbi: dbi, query: query)

				let values: [(String, String)] = cursor.compactMap {
					guard
						let key = String(mdbVal: $0.0),
						let value = String(mdbVal: $0.1)
					else {
						return nil
					}

					return (key, value)
				}

				try #require(values.count == 2)
				#expect(values[0] == ("a", "1"))
				#expect(values[1] == ("b", "2"))
			}
		}
	}

	@Test func greaterWithLimit() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "c", value: "3")
			try txn.set(dbi: dbi, key: "a", value: "1")
			try txn.set(dbi: dbi, key: "b", value: "2")

			try "a".withMDBVal { searchKey in
				let query = Query(comparison: .greater(searchKey), limit: 2)
				let cursor = try Cursor(transaction: txn, dbi: dbi, query: query)

				let values: [(String, String)] = cursor.compactMap {
					guard
						let key = String(mdbVal: $0.0),
						let value = String(mdbVal: $0.1)
					else {
						return nil
					}

					return (key, value)
				}

				try #require(values.count == 2)
				#expect(values[0] == ("b", "2"))
				#expect(values[1] == ("c", "3"))
			}
		}
	}

	@Test func backwardsScanCursor() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "c", value: "3")
			try txn.set(dbi: dbi, key: "a", value: "1")
			try txn.set(dbi: dbi, key: "b", value: "2")

			try "b".withMDBVal { searchKey in
				let query = Query(comparison: .less(searchKey))
				let cursor = try Cursor(transaction: txn, dbi: dbi, query: query)

				let values: [(String, String)] = cursor.compactMap {
					guard
						let key = String(mdbVal: $0.0),
						let value = String(mdbVal: $0.1)
					else {
						return nil
					}

					return (key, value)
				}

				try #require(values.count == 1)
				#expect(values[0] == ("a", "1"))
			}

		}
	}

	@Test func forwardEndingInclusiveCursor() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "c", value: "3")
			try txn.set(dbi: dbi, key: "a", value: "1")
			try txn.set(dbi: dbi, key: "b", value: "2")

			try "a".withMDBVal { searchKey in
				try "b".withMDBVal { endKey in
					let query = Query(comparison: .range(searchKey, endKey, inclusive: true))
					let cursor = try Cursor(transaction: txn, dbi: dbi, query: query)
					
					let values: [(String, String)] = cursor.compactMap {
						guard
							let key = String(mdbVal: $0.0),
							let value = String(mdbVal: $0.1)
						else {
							return nil
						}
						
						return (key, value)
					}
					
					try #require(values.count == 2)
					#expect(values[0] == ("a", "1"))
					#expect(values[1] == ("b", "2"))
				}
			}
		}
	}

	@Test func forwardEndingCursor() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "c", value: "3")
			try txn.set(dbi: dbi, key: "a", value: "1")
			try txn.set(dbi: dbi, key: "b", value: "2")

			try "a".withMDBVal { searchKey in
				try "b".withMDBVal { endKey in
					let query = Query(comparison: .range(searchKey, endKey, inclusive: false))
					let cursor = try Cursor(transaction: txn, dbi: dbi, query: query)

					let values: [(String, String)] = cursor.compactMap {
						guard
							let key = String(mdbVal: $0.0),
							let value = String(mdbVal: $0.1)
						else {
							return nil
						}

						return (key, value)
					}

					try #require(values.count == 1)
					#expect(values[0] == ("a", "1"))
				}
			}
		}
	}
}

extension LMDBTests {
	@Test func readOnlyTransaction() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		// the database must exist before trying a read-only transaction
		try Transaction.with(env: env, readOnly: false) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "hello", value: "goodbye")
		}
		
		try Transaction.with(env: env, readOnly: true) { txn in
			let dbi = try txn.open(name: "mydb")

			let value = try txn.getString(dbi: dbi, key: "hello")

			#expect(value == "goodbye")

			#expect(throws: MDBError.permissionDenied) {
				try txn.set(dbi: dbi, key: "hello", value: "goodbye")
			}
		}
	}
	
	@Test func concurrentAccess() async throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1, locking: true)
		let count = 100

		// use a transaction to first get the dbi
		let dbi = try Transaction.with(env: env) { txn in
			try txn.open(name: "mydb")
		}
		
		try Transaction.with(env: env) { txn in
			try txn.set(dbi: dbi, key: "hello", value: "goodbye")
		}

		let strings = try await withThrowingTaskGroup(of: String?.self) { group in
			for _ in 0..<count {
				group.addTask {
					try Transaction.with(env: env, readOnly: true) { txn in
						return try txn.getString(dbi: dbi, key: "hello")
					}
				}
				
				group.addTask {
					try Transaction.with(env: env) { txn in
						try txn.set(dbi: dbi, key: "hello", value: "hello")
					}

					return "hello"
				}
			}
			
			var values: [String?] = []
			
			for try await value in group {
				values.append(value)
			}
			
			return values
		}
		
		#expect(strings.count == count * 2)
		#expect(strings.contains("hello"))
		#expect(strings.contains("goodbye"))
	}
}
