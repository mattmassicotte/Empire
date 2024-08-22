extension UnsafeRawBufferPointer {
	func copyToByteArray() -> [UInt8] {
		.init(unsafeUninitializedCapacity: count) { destBuffer, initializedCount in
			let data = UnsafeMutableRawBufferPointer(start: destBuffer.baseAddress, count: count)

			data.copyMemory(from: self)

			initializedCount = count
		}
	}
}
