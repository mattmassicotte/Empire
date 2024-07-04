// Shifts the signed value into the unsigned range by adding Int.max. This preserves binary comparable sort ordering.
// Shifted_UInt = Signed + Signed.max + 1
// Signed = Shifted_UInt - Signed.max + 1
// However, easier say than done in a way that does not overflow

extension Int: Serializable {
	public var serializedSize: Int {
		MemoryLayout<Int>.size
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		let shifted: UInt

		if self >= 0 {
			shifted = UInt(self) + UInt(Int.max) + 1
		} else {
			shifted = UInt(self + Int.max + 1)
		}

		shifted.serialize(into: &buffer)
	}
}

extension Int: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let shifted = try UInt(buffer: &buffer)
		let max = UInt(Int.max) + 1

		if shifted > max {
			self = Int(shifted - max)
		} else {
			self = Int(max - shifted) * -1
		}
	}
}

