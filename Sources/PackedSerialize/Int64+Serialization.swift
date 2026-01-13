extension Int64: Serializable {
	public var serializedSize: Int {
		MemoryLayout<UInt64>.size
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		let shifted: UInt64

		if self == Self.min {
			UInt64(0).serialize(into: &buffer)
			return
		}

		if self >= 0 {
			shifted = UInt64(self) + UInt64(Self.max) + 1
		} else {
			shifted = UInt64(self + Self.max + 1)
		}

		shifted.serialize(into: &buffer)
	}
}

extension Int64: Deserializable {
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Int64 {
		let shifted = try UInt64.unpack(with: &deserializer)

		if shifted == 0 {
			return Self.min
		}

		let max = UInt64(Self.max) + 1

		if shifted > max {
			return Int64(shifted - max)
		} else {
			return Int64(max - shifted) * -1
		}
	}
}
