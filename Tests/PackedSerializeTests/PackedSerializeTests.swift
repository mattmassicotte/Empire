import Testing

import PackedSerialize

struct PackedSerializeTests {
	@Test func serializeUInt() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		UInt(42).serialize(into: &inputBuffer)
		UInt(142).serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try UInt(buffer: &outputBuffer) == 42)
		#expect(try UInt(buffer: &outputBuffer) == 142)
	}

	@Test func serializeString() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		"hello".serialize(into: &inputBuffer)
		"goodbye".serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try String(buffer: &outputBuffer) == "hello")
		#expect(try String(buffer: &outputBuffer) == "goodbye")
	}
}
