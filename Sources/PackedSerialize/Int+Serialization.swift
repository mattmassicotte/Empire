extension Int: Serializable {
	public var serializedSize: Int {
		bitWidth / 8
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		withUnsafeBytes(of: self.bigEndian) { ptr in
			buffer.copyMemory(from: ptr)
			buffer = UnsafeMutableRawBufferPointer(rebasing: buffer[ptr.count...])
		}
	}
}

extension Int: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		var value: Int = 0

		let data = UnsafeRawBufferPointer(start: buffer.baseAddress, count: MemoryLayout<Int>.size)

		withUnsafeMutableBytes(of: &value) { ptr in
			ptr.copyMemory(from: data)
		}

		buffer = UnsafeRawBufferPointer(rebasing: buffer[8...])

		self.init(bigEndian: value)
	}
}

