extension Bool: Serializable {
	public var serializedSize: Int {
		UInt8(self ? 1 : 0).serializedSize
	}
	
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		let value: UInt8 = self ? 1 : 0
		
		value.serialize(into: &buffer)
	}
}

extension Bool: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let value = try UInt8(buffer: &buffer)
		
		switch value {
		case 0:
			self = false
		case 1:
			self = true
		default:
			throw DeserializeError.invalidValue
		}
	}
}
