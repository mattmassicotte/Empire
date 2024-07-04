extension UInt: Serializable {
	public var serializedSize: Int {
		MemoryLayout<UInt>.size
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		withUnsafeBytes(of: self.bigEndian) { ptr in
			buffer.copyMemory(from: ptr)
			buffer = UnsafeMutableRawBufferPointer(rebasing: buffer[ptr.count...])
		}
	}
}

extension UInt: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		var value: UInt = 0
		let size = MemoryLayout<UInt>.size

		let data = UnsafeRawBufferPointer(start: buffer.baseAddress, count: size)

		withUnsafeMutableBytes(of: &value) { ptr in
			ptr.copyMemory(from: data)
		}

		buffer = UnsafeRawBufferPointer(rebasing: buffer[size...])

		self.init(bigEndian: value)
	}
}
