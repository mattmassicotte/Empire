import Foundation
import Testing

import Empire

@IndexKeyRecord("key")
struct DateKeyRecord: Hashable {
	let key: Date
}

@Suite(.serialized)
struct SelectTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/empire_select_store", isDirectory: true)
	
	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)
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
}
