import Foundation
import Testing

import LMDB

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
		var env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "hello", value: "goodbye")
		}

		env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			let value = try txn.getString(dbi: dbi, key: "hello")

			#expect(value == "goodbye")
		}
	}

	@Test func testMissingKey() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			#expect(try txn.getString(dbi: dbi, key: "hello") == nil)
		}
	}

	@Test func testCursor() throws {
		let env = try Environment(url: Self.storeURL, maxDatabases: 1)

		try Transaction.with(env: env) { txn in
			let dbi = try txn.open(name: "mydb")

			try txn.set(dbi: dbi, key: "c", value: "j")
			try txn.set(dbi: dbi, key: "a", value: "h")
			try txn.set(dbi: dbi, key: "b", value: "i")

			let cursor = try Cursor(transaction: txn, dbi: dbi)

			let aPairOpt = try "a".withMDBVal { key in
				try cursor.get(key: key, .setRange)
			}

			let aPair = try #require(aPairOpt)

			#expect(String(mdbVal: aPair.0) == "a")
			#expect(String(mdbVal: aPair.1) == "h")

			let bPairOpt = try "a".withMDBVal { key in
				try cursor.get(key: key, .next)
			}

			let bPair = try #require(bPairOpt)

			#expect(String(mdbVal: bPair.0) == "b")
			#expect(String(mdbVal: bPair.1) == "i")

			let cPairOpt = try "a".withMDBVal { key in
				try cursor.get(key: key, .next)
			}

			let cPair = try #require(cPairOpt)

			#expect(String(mdbVal: cPair.0) == "c")
			#expect(String(mdbVal: cPair.1) == "j")

			cursor.close()
		}
	}
}

