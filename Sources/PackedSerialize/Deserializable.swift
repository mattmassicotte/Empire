public protocol Deserializable {
	init(buffer: inout UnsafeRawBufferPointer) throws
}

enum DeserializeError: Error {
	case invalidLength
}

extension UInt: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		var value: UInt = 0

		let data = UnsafeRawBufferPointer(start: buffer.baseAddress, count: MemoryLayout<Int>.size)

		withUnsafeMutableBytes(of: &value) { ptr in
			ptr.copyMemory(from: data)
		}
		
		buffer = UnsafeRawBufferPointer(rebasing: buffer[8...])
		
		self.init(bigEndian: value)
	}
}

extension String: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let length = Int(try UInt(buffer: &buffer))
		guard length >= 0 else {
			throw DeserializeError.invalidLength
		}
		
		let sourceBuffer = UnsafeRawBufferPointer(start: buffer.baseAddress, count: length)
		
		self.init(unsafeUninitializedCapacity: length) { destBuffer in
			let data = UnsafeMutableRawBufferPointer(start: destBuffer.baseAddress, count: length)
			
			data.copyMemory(from: sourceBuffer)
			
			buffer = UnsafeRawBufferPointer(rebasing: buffer[length...])
			
			return length
		}
	}
}

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
