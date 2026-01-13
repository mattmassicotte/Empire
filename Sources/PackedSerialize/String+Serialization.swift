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
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Self {
		let value: String? = deserializer.rawSpan.withUnsafeBytes { buffer in
			guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: CChar.self) else {
				return nil
			}

			return String(cString: ptr, encoding: .utf8)
		}

		guard let value else {
			throw DeserializeError.invalidValue
		}

		try deserializer.advance(by: value.serializedSize)

		return value
	}
}
