public struct EmptyValue {
	public init() {}
}

extension EmptyValue: Sendable {}
extension EmptyValue: Equatable {}
extension EmptyValue: Hashable {}

extension EmptyValue: Serializable {
	public var serializedSize: Int {
		0
	}
	
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
	}
}

extension EmptyValue: Deserializable {
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending EmptyValue {
		EmptyValue()
	}
}
