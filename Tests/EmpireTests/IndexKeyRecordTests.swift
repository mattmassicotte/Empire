import Foundation
import Testing

import Empire

fileprivate struct TestRecord: Hashable {
	let a: String
	let b: Int
	var c: String
}

extension TestRecord: IndexKeyRecord {
	static var schemaHashValue: Int {
		42
	}
	
	var indexKeySerializedSize: Int {
		a.serializedSize + b.serializedSize
	}

	var fieldsSerializedSize: Int {
		c.serializedSize
	}
	
	func serialize(into buffer: inout SerializationBuffer) {
		a.serialize(into: &buffer.keyBuffer)
		b.serialize(into: &buffer.keyBuffer)
		c.serialize(into: &buffer.valueBuffer)
	}
	
	init(_ buffer: inout DeserializationBuffer) throws {
		self.a = try String(buffer: &buffer.keyBuffer)
		self.b = try Int(buffer: &buffer.keyBuffer)
		self.c = try String(buffer: &buffer.valueBuffer)
	}
}

extension TestRecord {
	static func select(in context: TransactionContext, a: String, b: Int) throws -> Self {
		try context.select(key: Tuple<String, Int>(a, b))
	}

	static func select(in context: TransactionContext, a: String, b: ComparisonOperator<Int>) throws -> [Self] {
		[]
	}

	static func select(in context: TransactionContext, a: ComparisonOperator<String>) throws -> [Self] {
		[]
	}
}

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

		let output: TestRecord = try await store.withTransaction { ctx in
			try ctx.select(key: Tuple<String, Int>("hello", 42))
		}

		#expect(output == record)
	}
}
