// doesn't work right yet

//extension Float: Serializable {
//	public var serializedSize: Int {
//		bitPattern.bitWidth / 8
//	}
//
//	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
//		withUnsafeBytes(of: self.bitPattern) { ptr in
//			buffer.copyMemory(from: ptr)
//			buffer = UnsafeMutableRawBufferPointer(rebasing: buffer[ptr.count...])
//		}
//	}
//}

//extension Float: Deserializable {
//	public init(buffer: inout UnsafeRawBufferPointer) throws {
//		var value: UInt32 = 0
//
//		let data = UnsafeRawBufferPointer(start: buffer.baseAddress, count: MemoryLayout<UInt32>.size)
//
//		withUnsafeMutableBytes(of: &value) { ptr in
//			ptr.copyMemory(from: data)
//		}
//
//		buffer = UnsafeRawBufferPointer(rebasing: buffer[8...])
//
//		self.init(bitPattern: value.bigEndian)
//	}
//}
