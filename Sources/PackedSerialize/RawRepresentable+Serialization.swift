extension RawRepresentable where RawValue: Serializable {
	public var serializedSize: Int { rawValue.serializedSize }
	
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		rawValue.serialize(into: &buffer)
	}
}

extension RawRepresentable where RawValue: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let value = try RawValue(buffer: &buffer)
		
		guard let rawRep = Self(rawValue: value) else {
			throw DeserializeError.invalidValue
		}
		
		self = rawRep
	}
}
