import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacroExpansion
import Testing

#if canImport(EmpireMacros)
import EmpireMacros

struct IndexKeyRecordMacroTests {
	let specs: [String: MacroSpec] = [
		"IndexKeyRecord": MacroSpec(type: IndexKeyRecordMacro.self)
	]

	@Test func testSingleFieldRecord() throws {
		assertMacroExpansion(
"""
@IndexKeyRecord("key")
struct KeyOnlyRecord {
	let key: Int
}
""",
			expandedSource:
"""
struct KeyOnlyRecord {
	let key: Int
}

extension KeyOnlyRecord : IndexKeyRecord {
	public typealias IndexKey = Tuple<Int>
	public typealias Fields = Tuple<EmptyValue>

	/// Input: "KeyOnlyRecord"
	public static var keyPrefix: Int {
		4973231345230152924
	}
	/// Input: "key: Int"
	public static var fieldsVersion: Int {
		8366809093122785258
	}

	public var fieldsSerializedSize: Int {
		0
	}

	public var indexKey: IndexKey {
		Tuple(key)
	}

	public func serialize(into buffer: inout SerializationBuffer) {
		key.serialize(into: &buffer.keyBuffer)
	}

	public init(_ buffer: inout DeserializationBuffer) throws {
		self.key = try Int(buffer: &buffer.keyBuffer)
	}
}

extension KeyOnlyRecord {
	public static func select(in context: TransactionContext, limit: Int? = nil, key: ComparisonOperator<Int>) throws -> [Self] {
		try context.select(query: Query(last: key, limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, key: Int) throws -> [Self] {
		try context.select(query: Query(last: .equals(key), limit: limit))
	}
}
""",
			macroSpecs: specs,
			indentationWidth: .tab,
			failureHandler: { Issue.record($0) }
		)
	}
	
	@Test func testKeyAndFieldRecord() throws {
		assertMacroExpansion(
"""
@IndexKeyRecord("key")
struct KeyFieldRecord {
	let key: Int
	let value: Int
}
""",
			expandedSource:
"""
struct KeyFieldRecord {
	let key: Int
	let value: Int
}

extension KeyFieldRecord : IndexKeyRecord {
	public typealias IndexKey = Tuple<Int>
	public typealias Fields = Tuple<Int>

	/// Input: "KeyFieldRecord"
	public static var keyPrefix: Int {
		5586469532794244204
	}
	/// Input: "key: Int,value: Int"
	public static var fieldsVersion: Int {
		1269469538501279226
	}

	public var fieldsSerializedSize: Int {
		value.serializedSize
	}

	public var indexKey: IndexKey {
		Tuple(key)
	}

	public func serialize(into buffer: inout SerializationBuffer) {
		key.serialize(into: &buffer.keyBuffer)
		value.serialize(into: &buffer.valueBuffer)
	}

	public init(_ buffer: inout DeserializationBuffer) throws {
		self.key = try Int(buffer: &buffer.keyBuffer)
		self.value = try Int(buffer: &buffer.valueBuffer)
	}
}

extension KeyFieldRecord {
	public static func select(in context: TransactionContext, limit: Int? = nil, key: ComparisonOperator<Int>) throws -> [Self] {
		try context.select(query: Query(last: key, limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, key: Int) throws -> [Self] {
		try context.select(query: Query(last: .equals(key), limit: limit))
	}
}
""",
			macroSpecs: specs,
			indentationWidth: .tab,
			failureHandler: { Issue.record($0) }
		)
	}
}
#endif

