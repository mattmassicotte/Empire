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
struct SelectTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/empire_select_store", isDirectory: true)
	
	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)
	}

	@Test func selectWithinTransaction() throws {
		let store = try Store(url: Self.storeURL)
		let record = CompoundKeyRecord(a: "hello", b: 42, c: "goodbye")
		try store.withTransaction { ctx in
			try ctx.insert(record)
		}

		let records: [CompoundKeyRecord] = try store.withTransaction { ctx in
			try CompoundKeyRecord.select(in: ctx, a: "hello", b: .greaterOrEqual(0))
		}

		#expect(records == [record])
	}

	@Test func selectDateGreaterThanDistantFuture() throws {
		let store = try Store(url: Self.storeURL)
		
		try store.withTransaction { ctx in
			try ctx.insert(DateKeyRecord(key: Date(timeIntervalSince1970: 700)))
			try ctx.insert(DateKeyRecord(key: Date(timeIntervalSince1970: 7000)))
			try ctx.insert(DateKeyRecord(key: Date(timeIntervalSince1970: 70000)))
		}
		
		let records = try store.withTransaction { ctx in
			try DateKeyRecord.select(in: ctx, key: .greaterThan(.distantPast))
		}
				
		let expected = [
			DateKeyRecord(key: Date(timeIntervalSince1970: 700)),
			DateKeyRecord(key: Date(timeIntervalSince1970: 7000)),
			DateKeyRecord(key: Date(timeIntervalSince1970: 70000)),
		]

		#expect(records == expected)
	}
	
	@Test func selectDateLessThanDistantFuture() throws {
		let store = try Store(url: Self.storeURL)
		
		try store.withTransaction { ctx in
			try ctx.insert(DateKeyRecord(key: Date(timeIntervalSince1970: 700)))
			try ctx.insert(DateKeyRecord(key: Date(timeIntervalSince1970: 7000)))
			try ctx.insert(DateKeyRecord(key: Date(timeIntervalSince1970: 70000)))
		}
		
		let records = try store.withTransaction { ctx in
			try DateKeyRecord.select(in: ctx, key: .lessThan(.distantFuture))
		}
				
		let expected = [
			DateKeyRecord(key: Date(timeIntervalSince1970: 70000)),
			DateKeyRecord(key: Date(timeIntervalSince1970: 7000)),
			DateKeyRecord(key: Date(timeIntervalSince1970: 700)),
		]

		#expect(records == expected)
	}
	
	@Test func selectSingleCompoundKeyRecord() throws {
		let record = CompoundKeyRecord(a: "hello", b: 42, c: "goodbye")

		let store = try Store(url: Self.storeURL)

		let records = try store.withTransaction { ctx in
			try ctx.insert(record)
			
			return try CompoundKeyRecord.select(in: ctx, a: "hello", b: 42)
		}

		#expect(records == [record])
	}
	
	@Test func contextSelectCompoundKeyRecord() throws {
		let store = try Store(url: Self.storeURL)

		let records: [CompoundKeyRecord] = try store.withTransaction { ctx in
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 42, c: "b"))
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 43, c: "c"))
			
			return try ctx.select(query: Query("hello", last: .equals(42)))
		}

		let expected = [
			CompoundKeyRecord(a: "hello", b: 42, c: "b"),
		]
		
		#expect(records == expected)
	}
	
	@Test func selectPartialCompoundKeyRecord() throws {
		let store = try Store(url: Self.storeURL)

		let records: [CompoundKeyRecord] = try store.withTransaction { ctx in
			try ctx.insert(CompoundKeyRecord(a: "helln", b: 40, c: "a")) // before
			try ctx.insert(CompoundKeyRecord(a: "hell", b: 40, c: "a"))
			
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 41, c: "b"))

			try ctx.insert(CompoundKeyRecord(a: "helloo", b: 40, c: "a")) // after
			try ctx.insert(CompoundKeyRecord(a: "hellp", b: 42, c: "c"))
			
			return try CompoundKeyRecord.select(in: ctx, a: "hello")
		}

		let expected = [
			CompoundKeyRecord(a: "hello", b: 40, c: "a"),
			CompoundKeyRecord(a: "hello", b: 41, c: "b"),
		]

		#expect(records == expected)
	}
	
	@Test func selectGreaterThanPartialCompoundKeyRecord() throws {
		let store = try Store(url: Self.storeURL)

		let records: [CompoundKeyRecord] = try store.withTransaction { ctx in
			try ctx.insert(CompoundKeyRecord(a: "helln", b: 40, c: "a")) // before
			try ctx.insert(CompoundKeyRecord(a: "hell", b: 40, c: "a"))
			
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 41, c: "b"))

			try ctx.insert(CompoundKeyRecord(a: "helloo", b: 40, c: "a")) // after
			try ctx.insert(CompoundKeyRecord(a: "hellp", b: 42, c: "c"))
			
			return try CompoundKeyRecord.select(in: ctx, a: "hello", b: .greaterThan(10))
		}

		let expected = [
			CompoundKeyRecord(a: "hello", b: 40, c: "a"),
			CompoundKeyRecord(a: "hello", b: 41, c: "b"),
		]

		#expect(records == expected)
	}
	
	@Test func selectGreaterOrEqualPartialCompoundKeyRecord() throws {
		let store = try Store(url: Self.storeURL)

		let records: [CompoundKeyRecord] = try store.withTransaction { ctx in
			try ctx.insert(CompoundKeyRecord(a: "helln", b: 40, c: "a")) // before
			try ctx.insert(CompoundKeyRecord(a: "hell", b: 40, c: "a"))
			
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 41, c: "b"))

			try ctx.insert(CompoundKeyRecord(a: "helloo", b: 40, c: "a")) // after
			try ctx.insert(CompoundKeyRecord(a: "hellp", b: 42, c: "c"))
			
			return try CompoundKeyRecord.select(in: ctx, a: "hello", b: .greaterOrEqual(40))
		}

		let expected = [
			CompoundKeyRecord(a: "hello", b: 40, c: "a"),
			CompoundKeyRecord(a: "hello", b: 41, c: "b"),
		]

		#expect(records == expected)
	}
	
	@Test func selectGreaterOrEqualFirstPartialCompoundKeyRecord() throws {
		let store = try Store(url: Self.storeURL)

		let records: [CompoundKeyRecord] = try store.withTransaction { ctx in
			try ctx.insert(CompoundKeyRecord(a: "helln", b: 40, c: "a")) // before
			try ctx.insert(CompoundKeyRecord(a: "hell", b: 40, c: "a"))
			
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 41, c: "b"))

			try ctx.insert(CompoundKeyRecord(a: "helloo", b: 40, c: "a")) // after
			try ctx.insert(CompoundKeyRecord(a: "hellp", b: 42, c: "c"))
			
			return try CompoundKeyRecord.select(in: ctx, a: .greaterThan("hello"))
		}

		let expected = [
			CompoundKeyRecord(a: "helloo", b: 40, c: "a"),
			CompoundKeyRecord(a: "hellp", b: 42, c: "c"),
		]

		#expect(records == expected)
	}
	
	@Test func selectLessThanPartialCompoundKeyRecord() throws {
		let store = try Store(url: Self.storeURL)

		let records: [CompoundKeyRecord] = try store.withTransaction { ctx in
			try ctx.insert(CompoundKeyRecord(a: "helln", b: 40, c: "a")) // before
			try ctx.insert(CompoundKeyRecord(a: "hell", b: 40, c: "a"))
			
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 41, c: "b"))

			try ctx.insert(CompoundKeyRecord(a: "helloo", b: 40, c: "a")) // after
			try ctx.insert(CompoundKeyRecord(a: "hellp", b: 42, c: "c"))
			
			return try CompoundKeyRecord.select(in: ctx, a: "hello", b: .lessThan(50))
		}

		let expected = [
			CompoundKeyRecord(a: "hello", b: 41, c: "b"),
			CompoundKeyRecord(a: "hello", b: 40, c: "a"),
		]

		#expect(records == expected)
	}
	
	@Test func selectLessOrEqualPartialCompoundKeyRecord() throws {
		let store = try Store(url: Self.storeURL)

		let records: [CompoundKeyRecord] = try store.withTransaction { ctx in
			try ctx.insert(CompoundKeyRecord(a: "helln", b: 40, c: "a")) // before
			try ctx.insert(CompoundKeyRecord(a: "hell", b: 40, c: "a"))
			
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 41, c: "b"))

			try ctx.insert(CompoundKeyRecord(a: "helloo", b: 40, c: "a")) // after
			try ctx.insert(CompoundKeyRecord(a: "hellp", b: 42, c: "c"))
			
			return try CompoundKeyRecord.select(in: ctx, a: "hello", b: .lessOrEqual(41))
		}

		let expected = [
			CompoundKeyRecord(a: "hello", b: 41, c: "b"),
			CompoundKeyRecord(a: "hello", b: 40, c: "a"),
		]

		#expect(records == expected)
	}
	
	@Test func selectRangePartialCompoundKeyRecord() throws {
		let store = try Store(url: Self.storeURL)

		let records: [CompoundKeyRecord] = try store.withTransaction { ctx in
			try ctx.insert(CompoundKeyRecord(a: "helln", b: 40, c: "a")) // before
			try ctx.insert(CompoundKeyRecord(a: "hell", b: 40, c: "a"))
			
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 40, c: "a"))
			try ctx.insert(CompoundKeyRecord(a: "hello", b: 41, c: "b"))

			try ctx.insert(CompoundKeyRecord(a: "helloo", b: 40, c: "a")) // after
			try ctx.insert(CompoundKeyRecord(a: "hellp", b: 42, c: "c"))
			
			return try CompoundKeyRecord.select(in: ctx, a: "hello", b: .range(39..<42))
		}

		let expected = [
			CompoundKeyRecord(a: "hello", b: 40, c: "a"),
			CompoundKeyRecord(a: "hello", b: 41, c: "b"),
		]

		#expect(records == expected)
	}
}
