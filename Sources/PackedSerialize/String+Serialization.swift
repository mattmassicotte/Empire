extension String: Serializable {
	public var serializedSize: Int {
		utf8.count + 1
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		let length = serializedSize

		// write the data
		withCString { ptr in
			let data = UnsafeRawBufferPointer(start: ptr, count: length)
			buffer.copyMemory(from: data)
		}

		buffer = UnsafeMutableRawBufferPointer(rebasing: buffer[length...])
	}
}

extension String: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let cStringPtr = buffer.assumingMemoryBound(to: CChar.self).baseAddress

		guard let cStringPtr else {
			throw DeserializeError.invalidValue
		}

		self.init(cString: cStringPtr)

		buffer = UnsafeRawBufferPointer(rebasing: buffer[serializedSize...])
	}
}
