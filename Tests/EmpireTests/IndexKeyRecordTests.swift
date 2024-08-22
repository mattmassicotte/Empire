import Foundation
import Testing

import Empire

@IndexKeyRecord("a", "b")
struct TestRecord: Hashable {
	let a: String
	let b: UInt
	var c: String
}

@IndexKeyRecord("key")
struct KeyOnlyRecord: Hashable {
	let key: UInt
}

/// Validates that a IndexKeyRecord can be public.
@IndexKeyRecord("key")
public struct PublicModel {
	let key: Int
}

extension TestRecord {
	static func select(in context: TransactionContext, a: String, b: ComparisonOperator<UInt>) throws -> [Self] {
		try context.select(query: Query(a, last: b))
	}

	static func select(in context: TransactionContext, a: ComparisonOperator<String>) throws -> [Self] {
		try context.select(query: Query(last: a))
	}
}

@Suite(.serialized)
struct IndexKeyRecordTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/store", isDirectory: true)

	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)
	}

	@Test func insertAndSelect() async throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(record)
		}

		let output: TestRecord? = try await store.withTransaction { ctx in
			try ctx.select(key: Tuple<String, UInt>("hello", 42))
		}

		#expect(output == record)
	}

	@Test func insertAndSelectCopy() async throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(record)
		}

		let output: TestRecord? = try await store.withTransaction { ctx in
			try ctx.selectCopy(key: Tuple<String, UInt>("hello", 42))
		}

		#expect(output == record)
	}

	@Test func selectGreater() async throws {
		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
		}

		let records = try await store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .greaterThan(40))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 42, c: "c"),
		]

		#expect(records == expected)
	}

	@Test func selectGreaterOrEqual() async throws {
		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
		}

		let records = try await store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .greaterOrEqual(41))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 42, c: "c"),
		]

		#expect(records == expected)
	}

	@Test func selectLessThan() async throws {
		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
		}

		let records = try await store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .lessThan(42))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 40, c: "a"),
		]

		#expect(records == expected)
	}

	@Test func selectLessThanOrEqual() async throws {
		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
		}

		let records = try await store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .lessOrEqual(41))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 40, c: "a"),
		]

		#expect(records == expected)
	}

	@Test func selectRange() async throws {
		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(TestRecord(a: "hello", b: 43, c: "d"))
		}

		let records = try await store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .range(41..<43))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 42, c: "c"),
		]

		#expect(records == expected)
	}

	@Test func selectClosedRange() async throws {
		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(TestRecord(a: "hello", b: 43, c: "d"))
		}

		let records = try await store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .closedRange(41...42))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 42, c: "c"),
		]

		#expect(records == expected)
	}

	@Test func selectWithin() async throws {
		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(TestRecord(a: "hello", b: 43, c: "d"))
		}

		let records = try await store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .within([41, 43]))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 43, c: "d"),
		]

		#expect(records == expected)
	}
}

extension IndexKeyRecordTests {
	@Test func delete() async throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		try await store.withTransaction { ctx in
			try ctx.insert(record)
			try ctx.delete(record)
		}

		let output = try await store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .equals(42))
		}

		#expect(output == [])
	}
}
