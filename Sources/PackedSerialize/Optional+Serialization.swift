extension Optional: Serializable where Wrapped: Serializable {
	public var serializedSize: Int {
		switch self {
		case .none:
			return false.serializedSize
		case let .some(value):
			return true.serializedSize + value.serializedSize
		}
	}
	
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		switch self {
		case .none:
			return false.serialize(into: &buffer)
		case let .some(value):
			true.serialize(into: &buffer)
			value.serialize(into: &buffer)
		}
	}
}

extension Optional: Deserializable where Wrapped: Deserializable {
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Self {
		guard try Bool.unpack(with: &deserializer) else {
			return .none
		}

		let value = try Wrapped.unpack(with: &deserializer)

		return .some(value)
	}
}
