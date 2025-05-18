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
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let shifted = try UInt64(buffer: &buffer)
		
		if shifted == 0 {
			self = Self.min
			return
		}
		
		let max = UInt64(Self.max) + 1

		if shifted > max {
			self = Int64(shifted - max)
		} else {
			self = Int64(max - shifted) * -1
		}
	}
}
