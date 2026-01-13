// Shifts the signed value into the unsigned range by adding Int.max. This preserves binary comparable sort ordering.
// Shifted_UInt = Signed + Signed.max + 1
// Signed = Shifted_UInt - Signed.max + 1

extension Int: Serializable {
	public var serializedSize: Int {
		MemoryLayout<UInt>.size
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		let shifted: UInt

		if self == Self.min {
			UInt(0).serialize(into: &buffer)
			return
		}
		
		if self >= 0 {
			shifted = UInt(self) + UInt(Int.max) + 1
		} else {
			shifted = UInt(self + Int.max + 1)
		}

		shifted.serialize(into: &buffer)
	}
}

extension Int: Deserializable {
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Int {
		let shifted = try UInt.unpack(with: &deserializer)

		if shifted == 0 {
			return Self.min
		}

		let max = UInt(Int.max) + 1

		if shifted > max {
			return Int(shifted - max)
		} else {
			return Int(max - shifted) * -1
		}
	}
}
