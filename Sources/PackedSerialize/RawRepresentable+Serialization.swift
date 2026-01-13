extension RawRepresentable where RawValue: Serializable {
	public var serializedSize: Int { rawValue.serializedSize }
	
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		rawValue.serialize(into: &buffer)
	}
}

extension RawRepresentable where RawValue: Deserializable, Self: Sendable {
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Self {
		let value = try RawValue.unpack(with: &deserializer)

		guard let rawRep = Self(rawValue: value) else {
			throw DeserializeError.invalidValue
		}

		return rawRep
	}
}

