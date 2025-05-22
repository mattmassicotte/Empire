import Foundation
import Testing

import Empire

@IndexKeyRecord("a", "b")
fileprivate struct ParentRecord: Hashable {
	let a: String
	let b: Int
	var c: String
}

@IndexKeyRecord("parentKey", "key")
fileprivate struct ChildRecord: Hashable {
	let parentKey: ParentRecord.IndexKey
	let key: Int
	var value: String

	func parent(in context: TransactionContext) throws -> ParentRecord? {
		try context.select(key: parentKey)
	}
}

@Suite(.serialized)
struct RelationshipTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/empire_relationship_store", isDirectory: true)

	let store: Store

	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)

		self.store = try Store(url: Self.storeURL)
	}

	@Test func insert() throws {
		let parent = ParentRecord(a: "hello", b: 42, c: "goodbye")
		let child = ChildRecord(parentKey: parent.indexKey, key: 1, value: "hello")

		let records: [ChildRecord] = try store.withTransaction { ctx in
			try ctx.insert(parent)
			try ctx.insert(child)

			return try ChildRecord.select(in: ctx, parentKey: parent.indexKey)
		}

		#expect(records == [child])
	}

	@Test func selectParent() throws {
		let parent = ParentRecord(a: "hello", b: 42, c: "goodbye")
		let child = ChildRecord(parentKey: parent.indexKey, key: 1, value: "hello")

		try store.withTransaction { ctx in
			try ctx.insert(parent)
			try ctx.insert(child)
		}

		let record = try store.withTransaction { ctx in
			try child.parent(in: ctx)
		}

		#expect(record == parent)
	}
}
