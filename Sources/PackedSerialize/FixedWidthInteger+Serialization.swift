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
	
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		var value: Self = 0
		let size = MemoryLayout<Self>.size

		let data = UnsafeRawBufferPointer(start: buffer.baseAddress, count: size)

		withUnsafeMutableBytes(of: &value) { ptr in
			ptr.copyMemory(from: data)
		}

		buffer = UnsafeRawBufferPointer(rebasing: buffer[size...])

		self.init(bigEndian: value)
	}
}

extension UInt8: Serializable {}
extension UInt8: Deserializable {}
extension UInt32: Serializable {}
extension UInt32: Deserializable {}
extension UInt: Serializable {}
extension UInt: Deserializable {}
