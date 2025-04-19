import Testing

import PackedSerialize

struct PackedSerializeTests {
	@Test func serializeUInt() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		UInt(42).serialize(into: &inputBuffer)
		UInt(142).serialize(into: &inputBuffer)
		UInt(0).serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try UInt(buffer: &outputBuffer) == 42)
		#expect(try UInt(buffer: &outputBuffer) == 142)
		#expect(try UInt(buffer: &outputBuffer) == 0)
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

	@Test func deserializeStringWithInvalidLength() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		UInt.max.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(throws: (any Error).self, performing: {
			try String(buffer: &outputBuffer)
		})
	}
}

#if canImport(Foundation)
import Foundation

extension PackedSerializeTests {
	@Test func serializeUUID() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		let uuidA = UUID()
		let uuidB = UUID()

		uuidA.serialize(into: &inputBuffer)
		uuidB.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try UUID(buffer: &outputBuffer) == uuidA)
		#expect(try UUID(buffer: &outputBuffer) == uuidB)
	}

	@Test func serializeData() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		let dataA = Data([1,2,3,4])
		let dataB = Data([0xfa, 0xdb, 0xcc, 0xbd])

		dataA.serialize(into: &inputBuffer)
		dataB.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Data(buffer: &outputBuffer) == dataA)
		#expect(try Data(buffer: &outputBuffer) == dataB)
	}

	@Test func serializeDate() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		// rounding is important because this serialization only has precision to the millisecond
		let dateA = Date(timeIntervalSince1970:Date.now.timeIntervalSince1970.rounded(.down))
		let dateB = Date(timeIntervalSince1970: 0.0)

		dateA.serialize(into: &inputBuffer)
		dateB.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Date(buffer: &outputBuffer) == dateA)
		#expect(try Date(buffer: &outputBuffer) == dateB)
	}
	
	@Test func serializeEmptyValue() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		let value = EmptyValue()
		
		#expect(value.serializedSize == 0)
		
		value.serialize(into: &inputBuffer)
		
		#expect(inputBuffer.baseAddress == buffer.baseAddress)
	}
}

#endif
