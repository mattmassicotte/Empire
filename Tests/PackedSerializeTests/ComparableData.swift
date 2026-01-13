import PackedSerialize

struct ComparableData<T: Serializable & Deserializable & SendableMetatype>: Comparable {
	let buffer: UnsafeMutableRawBufferPointer
	let input: T
	
	init(_ value: T) {
		self.input = value
		
		let size = value.serializedSize
		self.buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: 8)
		
		var localBuffer = buffer
		
		value.serialize(into: &localBuffer)
	}
	
	static func == (lhs: ComparableData, rhs: ComparableData) -> Bool {
		if lhs.buffer.count != rhs.buffer.count {
			return false
		}

		for pair in zip(lhs.buffer, rhs.buffer) {
			print("==", pair.0, pair.1)
			if pair.0 != pair.1 {
				return false
			}
		}

		return true
	}
	
	static func < (lhs: ComparableData, rhs: ComparableData) -> Bool {
		for pair in zip(lhs.buffer, rhs.buffer) {
			if pair.0 == pair.1 {
				continue
			}

			return pair.0 < pair.1
		}

		return false
	}
	
	static func sort(_ array: Array<T>) -> Array<T> {
		array
			.map(ComparableData.init)
			.sorted()
			.map { $0.input }
	}
}
