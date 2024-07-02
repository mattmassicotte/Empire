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

	@Test func serializeInt() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		(-42).serialize(into: &inputBuffer)
		42.serialize(into: &inputBuffer)
		142.serialize(into: &inputBuffer)
		(Int.min + 1).serialize(into: &inputBuffer)
		Int.max.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Int(buffer: &outputBuffer) == -42)
		#expect(try Int(buffer: &outputBuffer) == 42)
		#expect(try Int(buffer: &outputBuffer) == 142)
		#expect(try Int(buffer: &outputBuffer) == (Int.min + 1))
		#expect(try Int(buffer: &outputBuffer) == Int.max)
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

#if canImport(Foundation)
import Foundation

extension PackedSerializeTests {
	@Test func serializeUUID() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		let uuid = UUID()

		uuid.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try UUID(buffer: &outputBuffer) == uuid)
	}
}

#endif
