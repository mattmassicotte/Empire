import PackedSerialize

// This process is currently lossy: labels are discarded.

extension LabelledTuple: Serializable where repeat each Element: Serializable {
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		for element in repeat each elements {
			element.1.serialize(into: &buffer)
		}
	}

	public var serializedSize: Int {
		var length = 0

		for element in repeat each elements {
			length += element.1.serializedSize
		}

		return length
	}
}

extension LabelledTuple: Deserializable where repeat each Element: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let unnamedElements: (repeat each Element) = (repeat try (each Element).init(buffer: &buffer))

		self.elements = (repeat (name: "", value: each unnamedElements))
	}
}

extension Tuple: Serializable where repeat each Element: Serializable {
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		for element in repeat each elements {
			element.serialize(into: &buffer)
		}
	}

	public var serializedSize: Int {
		var length = 0

		for element in repeat each elements {
			length += element.serializedSize
		}

		return length
	}
}

