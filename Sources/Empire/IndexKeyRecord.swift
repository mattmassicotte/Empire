import PackedSerialize

/// Requirements for a type stored in an Empire database.
public protocol IndexKeyRecord {
	static var schemaHashValue: Int { get }

	var indexKeySerializedSize: Int { get }
	var fieldsSerializedSize: Int { get }

	func serialize(into buffer: inout SerializationBuffer)
	init(_ buffer: inout DeserializationBuffer) throws
}
