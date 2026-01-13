public protocol Serializable {
	var serializedSize: Int { get }
	func serialize(into buffer: inout UnsafeMutableRawBufferPointer)
}

public protocol Deserializable {
//	init(buffer: inout UnsafeRawBufferPointer) throws

	static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Self
}

public enum DeserializeError: Error, Equatable {
	case invalidLength
	case invalidValue
	case endOfBufferReached(Int, Int)
}
