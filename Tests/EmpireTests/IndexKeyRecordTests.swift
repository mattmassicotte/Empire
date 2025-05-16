import Foundation
import Testing

import Empire

@IndexKeyRecord("a", "b")
struct TestRecord: Hashable {
	let a: String
	let b: UInt
	var c: String
}

@IndexKeyRecord(keyPrefix: 3787247394, "a", "b")
struct LessThanTestRecord: Hashable {
	let a: String
	let b: UInt
	var c: String
}

@IndexKeyRecord(keyPrefix: 3787247396, "a", "b")
struct GreaterThanTestRecord: Hashable {
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
public struct PublicModel : Sendable {
	let key: Int
}

@Suite(.serialized)
struct IndexKeyRecordTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/empire_test_store", isDirectory: true)

	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)
	}

	/// If this test fails, many other tests could fail too
	@Test func validateTestRecords() {
		#expect(TestRecord.keyPrefix < GreaterThanTestRecord.keyPrefix)
		#expect(TestRecord.keyPrefix + 1 == GreaterThanTestRecord.keyPrefix)
		#expect(TestRecord.fieldsVersion == GreaterThanTestRecord.fieldsVersion)

		#expect(TestRecord.keyPrefix > LessThanTestRecord.keyPrefix)
		#expect(TestRecord.keyPrefix - 1 == LessThanTestRecord.keyPrefix)
		#expect(TestRecord.fieldsVersion == LessThanTestRecord.fieldsVersion)
	}
	
	@Test func insertAndSelect() throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(record)
		}

		let output: TestRecord? = try store.withTransaction { ctx in
			try ctx.select(key: TestRecord.IndexKey("hello", 42))
		}

		#expect(output == record)
	}

	@Test func insertAndSelectSingleRecord() throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(record)
		}

		let records = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: 42)
		}

		#expect(records == [record])
	}

	@Test func insertRecordWithLargeField() throws {
		let record = TestRecord(a: "hello", b: 42, c: String(repeating: "z", count: 1024*10))

		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(record)
		}

		let output: TestRecord? = try store.withTransaction { ctx in
			try ctx.select(key: TestRecord.IndexKey("hello", 42))
		}

		#expect(output == record)
	}
	
	@Test func insertAndSelectCopy() throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(record)
		}

		let output: TestRecord? = try store.withTransaction { ctx in
			try ctx.selectCopy(key: TestRecord.IndexKey("hello", 42))
		}

		#expect(output == record)
	}
	
	@Test func selectGreater() throws {
		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(GreaterThanTestRecord(a: "hello", b: 41, c: "b"))
		}

		let records = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .greaterThan(40))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 42, c: "c"),
		]

		#expect(records == expected)
	}

	@Test func selectGreaterOrEqual() throws {
		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(GreaterThanTestRecord(a: "hello", b: 41, c: "b"))
		}

		let records = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .greaterOrEqual(41))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 42, c: "c"),
		]

		#expect(records == expected)
	}

	@Test func selectLessThan() throws {
		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(LessThanTestRecord(a: "hello", b: 41, c: "b"))
		}

		let records = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .lessThan(42))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 40, c: "a"),
		]

		#expect(records == expected)
	}

	@Test func selectLessThanOrEqual() throws {
		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(LessThanTestRecord(a: "hello", b: 41, c: "b"))
		}

		let records = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .lessOrEqual(41))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 40, c: "a"),
		]

		#expect(records == expected)
	}

	@Test func selectRange() throws {
		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(TestRecord(a: "hello", b: 43, c: "d"))
			try ctx.insert(LessThanTestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(GreaterThanTestRecord(a: "hello", b: 41, c: "b"))
		}

		let records = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .range(41..<43))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 42, c: "c"),
		]

		#expect(records == expected)
	}

	@Test func selectClosedRange() throws {
		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(TestRecord(a: "hello", b: 43, c: "d"))
			try ctx.insert(LessThanTestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(GreaterThanTestRecord(a: "hello", b: 41, c: "b"))
		}

		let records = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .closedRange(41...42))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
			TestRecord(a: "hello", b: 42, c: "c"),
		]

		#expect(records == expected)
	}

	@Test func selectWithin() throws {
		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(TestRecord(a: "hello", b: 43, c: "d"))
		}

		let records = try store.withTransaction { ctx in
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
	@Test func selectGreaterWithLimit() throws {
		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(TestRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(TestRecord(a: "hello", b: 41, c: "b"))
			try ctx.insert(TestRecord(a: "hello", b: 42, c: "c"))
			try ctx.insert(GreaterThanTestRecord(a: "hello", b: 41, c: "b"))
		}

		let records: [TestRecord] = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, limit: 1, a: "hello", b: .greaterThan(40))
		}

		let expected = [
			TestRecord(a: "hello", b: 41, c: "b"),
		]

		#expect(records == expected)
	}
}

extension IndexKeyRecordTests {
	@Test func insertAndSelectViaStore() throws {
		let store = try Store(url: Self.storeURL)

		let input = TestRecord(a: "hello", b: 40, c: "a")
		
		try store.insert(input)
		let record: TestRecord? = try store.select(key: input.indexKey)

		#expect(record == input)
	}
	
	@Test func insertAndDeleteViaStore() throws {
		let store = try Store(url: Self.storeURL)

		let input = TestRecord(a: "hello", b: 40, c: "a")
		
		try store.insert(input)
		#expect(try store.select(key: input.indexKey) == input)
		
		try store.delete(input)
		#expect(try store.select(key: input.indexKey) == Optional<TestRecord>.none)
	}
}

extension IndexKeyRecordTests {
	@Test func deleteEntireRecord() throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(record)
			try ctx.delete(record)
		}

		let output = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .equals(42))
		}

		#expect(output == [])
	}
	
	@Test func deleteViaKey() throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(record)
			try TestRecord.delete(in: ctx, a: record.a, b: record.b)
		}

		let output = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .equals(42))
		}

		#expect(output == [])
	}
	
	@Test func deleteInstance() throws {
		let record = TestRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(record)
			try record.delete(in: ctx)
		}

		let output = try store.withTransaction { ctx in
			try TestRecord.select(in: ctx, a: "hello", b: .equals(42))
		}

		#expect(output == [])
	}
}

extension IndexKeyRecordTests {
	@IndexKeyRecord(validated: 3622976456, "key")
	struct ValidatedRecord: Sendable {
		let key: Int
		let a: Int
		let b: String
		let c: Data
	}

	@Test func validatedVersion() {
		#expect(ValidatedRecord.fieldsVersion == 3622976456)
	}

	@IndexKeyRecord(keyPrefix: 5, fieldsVersion: 10, "key")
	struct CustomVersion: Sendable {
		let key: Int
	}
	
	@Test func customVersions() {
		#expect(CustomVersion.keyPrefix == 5)
		#expect(CustomVersion.fieldsVersion == 10)
	}
}
