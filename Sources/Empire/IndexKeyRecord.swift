import PackedSerialize

/// Requirements for a type stored in an Empire database.
public protocol IndexKeyRecord {
	associatedtype IndexKey: Serializable & IndexKeyComparable

	static var schemaVersion: Int { get }

	var indexKeySerializedSize: Int { get }
	var fieldsSerializedSize: Int { get }
	var indexKey: IndexKey { get }

	func serialize(into buffer: inout SerializationBuffer)
	init(_ buffer: inout DeserializationBuffer) throws
}

