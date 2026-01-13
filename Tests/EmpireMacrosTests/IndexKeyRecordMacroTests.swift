import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacroExpansion
import Testing

#if canImport(EmpireMacros)
import EmpireMacros

struct IndexKeyRecordMacroTests {
	let specs: [String: MacroSpec] = [
		"IndexKeyRecord": MacroSpec(type: IndexKeyRecordMacro.self)
	]

	@Test func singleFieldRecord() throws {
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

extension KeyOnlyRecord: IndexKeyRecord {
	public typealias IndexKey = Tuple<Int>
	public typealias Fields = Tuple<EmptyValue>

	/// Input: "KeyOnlyRecord"
	public static var keyPrefix: IndexKeyRecordHash {
		642254044
	}

	/// Input: ""
	public static var fieldsVersion: IndexKeyRecordHash {
		0
	}

	public var indexKey: IndexKey {
		Tuple(key)
	}

	public var fields: Fields {
		Tuple(EmptyValue())
	}

	public func serialize(into buffer: inout SerializationBuffer) {
		key.serialize(into: &buffer.keyBuffer)
	}

	public static func deserialize(with deserializer: consuming RecordDeserializer) throws(DeserializeError) -> sending Self {
		let key = try Int.unpack(with: &deserializer.keyDeserializer)

		return Self(key: key)
	}
}

extension KeyOnlyRecord {
	public static func select(in context: TransactionContext, limit: Int? = nil, key: ComparisonOperator<Int>) throws -> [Self] {
		try context.select(query: Query(last: key, limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, key: Int) throws -> [Self] {
		try context.select(query: Query(last: .equals(key), limit: limit))
	}
	public static func delete(in context: TransactionContext, key: Int) throws {
		try context.delete(recordType: Self.self, key: Tuple(key))
	}
}
""",
			macroSpecs: specs,
			indentationWidth: .tab,
			failureHandler: { Issue.record($0) }
		)
	}
	
	@Test func keyAndFieldRecord() throws {
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

extension KeyFieldRecord: IndexKeyRecord {
	public typealias IndexKey = Tuple<Int>
	public typealias Fields = Tuple<Int>

	/// Input: "KeyFieldRecord"
	public static var keyPrefix: IndexKeyRecordHash {
		314461292
	}

	/// Input: "Int"
	public static var fieldsVersion: IndexKeyRecordHash {
		610305871
	}

	public var indexKey: IndexKey {
		Tuple(key)
	}

	public var fields: Fields {
		Tuple(value)
	}

	public func serialize(into buffer: inout SerializationBuffer) {
		key.serialize(into: &buffer.keyBuffer)
		value.serialize(into: &buffer.valueBuffer)
	}

	public static func deserialize(with deserializer: consuming RecordDeserializer) throws(DeserializeError) -> sending Self {
		let key = try Int.unpack(with: &deserializer.keyDeserializer)
		let value = try Int.unpack(with: &deserializer.fieldsDeserializer)

		return Self(key: key, value: value)
	}
}

extension KeyFieldRecord {
	public static func select(in context: TransactionContext, limit: Int? = nil, key: ComparisonOperator<Int>) throws -> [Self] {
		try context.select(query: Query(last: key, limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, key: Int) throws -> [Self] {
		try context.select(query: Query(last: .equals(key), limit: limit))
	}
	public static func delete(in context: TransactionContext, key: Int) throws {
		try context.delete(recordType: Self.self, key: Tuple(key))
	}
}
""",
			macroSpecs: specs,
			indentationWidth: .tab,
			failureHandler: { Issue.record($0) }
		)
	}
	
	@Test func keyAndFieldsRecord() throws {
		assertMacroExpansion(
"""
@IndexKeyRecord("key")
struct KeyFieldsRecord {
	let key: Int
	let a: Int
	let b: String
}
""",
			expandedSource:
"""
struct KeyFieldsRecord {
	let key: Int
	let a: Int
	let b: String
}

extension KeyFieldsRecord: IndexKeyRecord {
	public typealias IndexKey = Tuple<Int>
	public typealias Fields = Tuple<Int, String>

	/// Input: "KeyFieldsRecord"
	public static var keyPrefix: IndexKeyRecordHash {
		932782057
	}

	/// Input: "Int,String"
	public static var fieldsVersion: IndexKeyRecordHash {
		3722219886
	}

	public var indexKey: IndexKey {
		Tuple(key)
	}

	public var fields: Fields {
		Tuple(a, b)
	}

	public func serialize(into buffer: inout SerializationBuffer) {
		key.serialize(into: &buffer.keyBuffer)
		a.serialize(into: &buffer.valueBuffer)
	b.serialize(into: &buffer.valueBuffer)
	}

	public static func deserialize(with deserializer: consuming RecordDeserializer) throws(DeserializeError) -> sending Self {
		let key = try Int.unpack(with: &deserializer.keyDeserializer)
		let a = try Int.unpack(with: &deserializer.fieldsDeserializer)
		let b = try String.unpack(with: &deserializer.fieldsDeserializer)

		return Self(key: key, a: a, b: b)
	}
}

extension KeyFieldsRecord {
	public static func select(in context: TransactionContext, limit: Int? = nil, key: ComparisonOperator<Int>) throws -> [Self] {
		try context.select(query: Query(last: key, limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, key: Int) throws -> [Self] {
		try context.select(query: Query(last: .equals(key), limit: limit))
	}
	public static func delete(in context: TransactionContext, key: Int) throws {
		try context.delete(recordType: Self.self, key: Tuple(key))
	}
}
""",
			macroSpecs: specs,
			indentationWidth: .tab,
			failureHandler: { Issue.record($0) }
		)
	}
	
	@Test func staticProperties() throws {
		assertMacroExpansion(
"""
@IndexKeyRecord("key")
struct KeyOnlyRecord {
	let key: Int
	static let value: Int
}
""",
			expandedSource:
"""
struct KeyOnlyRecord {
	let key: Int
	static let value: Int
}

extension KeyOnlyRecord: IndexKeyRecord {
	public typealias IndexKey = Tuple<Int>
	public typealias Fields = Tuple<EmptyValue>

	/// Input: "KeyOnlyRecord"
	public static var keyPrefix: IndexKeyRecordHash {
		642254044
	}

	/// Input: ""
	public static var fieldsVersion: IndexKeyRecordHash {
		0
	}

	public var indexKey: IndexKey {
		Tuple(key)
	}

	public var fields: Fields {
		Tuple(EmptyValue())
	}

	public func serialize(into buffer: inout SerializationBuffer) {
		key.serialize(into: &buffer.keyBuffer)
	}

	public static func deserialize(with deserializer: consuming RecordDeserializer) throws(DeserializeError) -> sending Self {
		let key = try Int.unpack(with: &deserializer.keyDeserializer)

		return Self(key: key)
	}
}

extension KeyOnlyRecord {
	public static func select(in context: TransactionContext, limit: Int? = nil, key: ComparisonOperator<Int>) throws -> [Self] {
		try context.select(query: Query(last: key, limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, key: Int) throws -> [Self] {
		try context.select(query: Query(last: .equals(key), limit: limit))
	}
	public static func delete(in context: TransactionContext, key: Int) throws {
		try context.delete(recordType: Self.self, key: Tuple(key))
	}
}
""",
			macroSpecs: specs,
			indentationWidth: .tab,
			failureHandler: { Issue.record($0) }
		)
	}
	
	@Test func compositeKeyRecord() throws {
		assertMacroExpansion(
"""
@IndexKeyRecord("a", "b", "c")
struct Record {
	let a: Int
	let b: String
	let c: UUID
}
""",
			expandedSource:
"""
struct Record {
	let a: Int
	let b: String
	let c: UUID
}

extension Record: IndexKeyRecord {
	public typealias IndexKey = Tuple<Int, String, UUID>
	public typealias Fields = Tuple<EmptyValue>

	/// Input: "Record"
	public static var keyPrefix: IndexKeyRecordHash {
		464924881
	}

	/// Input: ""
	public static var fieldsVersion: IndexKeyRecordHash {
		0
	}

	public var indexKey: IndexKey {
		Tuple(a, b, c)
	}

	public var fields: Fields {
		Tuple(EmptyValue())
	}

	public func serialize(into buffer: inout SerializationBuffer) {
		a.serialize(into: &buffer.keyBuffer)
	b.serialize(into: &buffer.keyBuffer)
	c.serialize(into: &buffer.keyBuffer)
	}

	public static func deserialize(with deserializer: consuming RecordDeserializer) throws(DeserializeError) -> sending Self {
		let a = try Int.unpack(with: &deserializer.keyDeserializer)
		let b = try String.unpack(with: &deserializer.keyDeserializer)
		let c = try UUID.unpack(with: &deserializer.keyDeserializer)

		return Self(a: a, b: b, c: c)
	}
}

extension Record {
	public static func select(in context: TransactionContext, limit: Int? = nil, a: ComparisonOperator<Int>) throws -> [Self] {
		try context.select(query: Query(last: a, limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, a: Int) throws -> [Self] {
		try context.select(query: Query(last: .equals(a), limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, a: Int, b: ComparisonOperator<String>) throws -> [Self] {
		try context.select(query: Query(a, last: b, limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, a: Int, b: String) throws -> [Self] {
		try context.select(query: Query(a, last: .equals(b), limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, a: Int, b: String, c: ComparisonOperator<UUID>) throws -> [Self] {
		try context.select(query: Query(a, b, last: c, limit: limit))
	}
	public static func select(in context: TransactionContext, limit: Int? = nil, a: Int, b: String, c: UUID) throws -> [Self] {
		try context.select(query: Query(a, b, last: .equals(c), limit: limit))
	}
	public static func delete(in context: TransactionContext, a: Int, b: String, c: UUID) throws {
		try context.delete(recordType: Self.self, key: Tuple(a, b, c))
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
