public protocol Serializable {
	var serializedSize: Int { get }
	func serialize(into buffer: inout UnsafeMutableRawBufferPointer)
}

public protocol Deserializable {
	init(buffer: inout UnsafeRawBufferPointer) throws
}

enum DeserializeError: Error {
	case invalidLength
	case invalidValue
}
