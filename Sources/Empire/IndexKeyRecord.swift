import PackedSerialize

/// Requirements for a type stored in an Empire database.
public protocol IndexKeyRecord {
	associatedtype IndexKey: Serializable & Deserializable & IndexKeyComparable
	associatedtype Fields: Serializable & Deserializable

	static var keyPrefix: Int { get }
	static var fieldsVersion: Int { get }

	var fieldsSerializedSize: Int { get }
	var indexKey: IndexKey { get }

	func serialize(into buffer: inout SerializationBuffer)
	init(_ buffer: inout DeserializationBuffer) throws
}
