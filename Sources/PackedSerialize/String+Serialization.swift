extension String: Serializable {
	public var serializedSize: Int {
		let length = utf8.count

		return UInt(length).serializedSize + length
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		let length = utf8.count

		// write the length
		UInt(length).serialize(into: &buffer)

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
		let length = Int(try UInt(buffer: &buffer))
		guard length >= 0 else {
			throw DeserializeError.invalidLength
		}

		let sourceBuffer = UnsafeRawBufferPointer(start: buffer.baseAddress, count: length)

		self.init(unsafeUninitializedCapacity: length) { destBuffer in
			let data = UnsafeMutableRawBufferPointer(start: destBuffer.baseAddress, count: length)

			data.copyMemory(from: sourceBuffer)

			buffer = UnsafeRawBufferPointer(rebasing: buffer[length...])

			return length
		}
	}
}
