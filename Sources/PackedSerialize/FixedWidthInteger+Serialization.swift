extension FixedWidthInteger where Self.Magnitude: UnsignedInteger {
	public var serializedSize: Int {
		MemoryLayout<Self>.size
	}
	
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		withUnsafeBytes(of: self.bigEndian) { ptr in
			buffer.copyMemory(from: ptr)
			buffer = UnsafeMutableRawBufferPointer(rebasing: buffer[ptr.count...])
		}
	}
}

extension UInt8: Serializable {}
extension UInt8: Deserializable {}
extension UInt32: Serializable {}
extension UInt32: Deserializable {}
extension UInt64: Serializable {}
extension UInt64: Deserializable {}
extension UInt: Serializable {}
extension UInt: Deserializable {}

extension FixedWidthInteger where Self: BitwiseCopyable & Sendable & UnsignedInteger {
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Self {
		let value = try deserializer.unsafeLoad(of: Self.self, sized: MemoryLayout<Self>.size)

		return Self.init(bigEndian: value)
	}
}
