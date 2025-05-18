import Foundation
import Testing

import Empire

@IndexKeyRecord("key")
fileprivate struct DateKeyRecord: Hashable {
	let key: Date
}

@IndexKeyRecord("a", "b")
fileprivate struct CompoundKeyRecord: Hashable {
	let a: String
	let b: Int
	var c: String
}

@Suite(.serialized)
struct InsertTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/empire_insert_store", isDirectory: true)

	let store: Store

	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)

		self.store = try Store(url: Self.storeURL)
	}

	@Test func insert() throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let output: TestRecord? = try store.withTransaction { ctx in
			try ctx.insert(record)

			return try ctx.select(key: record.indexKey)
		}

		#expect(output == record)
	}

	@Test func insertWithInstanceMethod() throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		try record.insert(in: store)

		let output: TestRecord? = try store.select(key: record.indexKey)

		#expect(output == record)
	}
}
