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
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Bool {
		let value = try UInt8.unpack(with: &deserializer)

		switch value {
		case 0:
			return false
		case 1:
			return true
		default:
			throw DeserializeError.invalidValue
		}
	}
}
