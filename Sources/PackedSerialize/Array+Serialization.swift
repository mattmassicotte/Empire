extension Array: Serializable where Element: Serializable {
	public var serializedSize: Int {
		UInt(count).serializedSize + reduce(0, { $0 + $1.serializedSize })
	}
	
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		UInt(count).serialize(into: &buffer)
		
		for element in self {
			element.serialize(into: &buffer)
		}
	}
}

extension Array: Deserializable where Element: Deserializable {
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Array<Element> {
		let count = try UInt.unpack(with: &deserializer)

		var array: Self = []

		for _ in 0..<count {
			array.append(try Element.unpack(with: &deserializer))
		}

		return array
	}
}
