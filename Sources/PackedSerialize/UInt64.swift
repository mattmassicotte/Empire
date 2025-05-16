extension Int64: Serializable {
	public var serializedSize: Int {
		MemoryLayout<Self>.size
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		let shifted: UInt64

		if self >= 0 {
			shifted = UInt64(self) + UInt64(Int64.max) + 1
		} else {
			shifted = UInt64(self + Int64.max + 1)
		}

		shifted.serialize(into: &buffer)
	}
}

extension Int64: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let shifted = try UInt64(buffer: &buffer)
		let max = UInt64(Int64.max) + 1

		if shifted > max {
			self = Int64(shifted - max)
		} else {
			self = Int64(max - shifted) * -1
		}
	}
}
