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
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let count = try UInt(buffer: &buffer)
		
		var array: Self = []
		
		for _ in 0..<count {
			array.append(try Element(buffer: &buffer))
		}
		
		self = array
	}
}
