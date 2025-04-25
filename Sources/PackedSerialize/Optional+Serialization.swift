extension Optional: Serializable where Wrapped: Serializable {
	public var serializedSize: Int {
		switch self {
		case .none:
			return false.serializedSize
		case let .some(value):
			return true.serializedSize + value.serializedSize
		}
	}
	
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		switch self {
		case .none:
			return false.serialize(into: &buffer)
		case let .some(value):
			true.serialize(into: &buffer)
			value.serialize(into: &buffer)
		}
	}
}

extension Optional: Deserializable where Wrapped: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		guard try Bool(buffer: &buffer) else {
			self = .none
			return
		}
		
		let value = try Wrapped(buffer: &buffer)

		self = .some(value)
	}
}
