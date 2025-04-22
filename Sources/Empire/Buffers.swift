import CLMDB

/// A mutable data buffer for reading and writing serialized data.
public struct SerializationBuffer {
	public var keyBuffer: UnsafeMutableRawBufferPointer
	public var valueBuffer: UnsafeMutableRawBufferPointer
	
	init(keySize: Int, valueSize: Int) {
		self.keyBuffer = UnsafeMutableRawBufferPointer.allocate(
			byteCount: keySize,
			alignment: MemoryLayout<UInt8>.alignment
		)
		self.valueBuffer = UnsafeMutableRawBufferPointer.allocate(
			byteCount: valueSize,
			alignment: MemoryLayout<UInt8>.alignment
		)
	}
}

/// An immutable data buffer for reading serialized data.
public struct DeserializationBuffer {
	public var keyBuffer: UnsafeRawBufferPointer
	public var valueBuffer: UnsafeRawBufferPointer

	init(keyBuffer: UnsafeRawBufferPointer, valueBuffer: UnsafeRawBufferPointer) {
		self.keyBuffer = keyBuffer
		self.valueBuffer = valueBuffer
	}

	init(key: MDB_val, value: MDB_val) {
		self.keyBuffer = key.bufferPointer
		self.valueBuffer = value.bufferPointer
	}
}
