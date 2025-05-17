import Testing

import PackedSerialize

enum HasRawRep: Int {
	case one
	case two
	case three
}

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
		Int.min.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Int(buffer: &outputBuffer) == -42)
		#expect(try Int(buffer: &outputBuffer) == 42)
		#expect(try Int(buffer: &outputBuffer) == 142)
		#expect(try Int(buffer: &outputBuffer) == (Int.min + 1))
		#expect(try Int(buffer: &outputBuffer) == Int.max)
		#expect(try Int(buffer: &outputBuffer) == Int.min)
	}
	
	@Test func serializeInt64() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		(-42).serialize(into: &inputBuffer)
		42.serialize(into: &inputBuffer)
		142.serialize(into: &inputBuffer)
		(Int64.min + 1).serialize(into: &inputBuffer)
		Int64.max.serialize(into: &inputBuffer)
		Int64.min.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Int(buffer: &outputBuffer) == -42)
		#expect(try Int(buffer: &outputBuffer) == 42)
		#expect(try Int(buffer: &outputBuffer) == 142)
		#expect(try Int(buffer: &outputBuffer) == (Int64.min + 1))
		#expect(try Int(buffer: &outputBuffer) == Int64.max)
		#expect(try Int(buffer: &outputBuffer) == Int64.min)
	}

	@Test func serializeUInt8() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		UInt8(42).serialize(into: &inputBuffer)
		UInt8(142).serialize(into: &inputBuffer)
		UInt8(0).serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try UInt8(buffer: &outputBuffer) == 42)
		#expect(try UInt8(buffer: &outputBuffer) == 142)
		#expect(try UInt8(buffer: &outputBuffer) == 0)
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
	
	@Test func serializeBoolString() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		true.serialize(into: &inputBuffer)
		false.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Bool(buffer: &outputBuffer) == true)
		#expect(try Bool(buffer: &outputBuffer) == false)
	}
	
	@Test func deserializeBoolWithInvalidValue() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		UInt8(4).serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(throws: (any Error).self, performing: {
			try Bool(buffer: &outputBuffer)
		})
	}
	
	@Test func serializeOptionalString() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		Optional<String>.some("hello").serialize(into: &inputBuffer)
		Optional<String>.some("goodbye").serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try String?(buffer: &outputBuffer) == "hello")
		#expect(try String?(buffer: &outputBuffer) == "goodbye")
	}
	
	@Test func serializeStringArray() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		["1", "2", "3"].serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try [String](buffer: &outputBuffer) == ["1", "2", "3"])
	}
	
	@Test func rawRepresentable() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		HasRawRep.two.serialize(into: &inputBuffer)
		HasRawRep.one.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try HasRawRep(buffer: &outputBuffer) == HasRawRep.two)
		#expect(try HasRawRep(buffer: &outputBuffer) == HasRawRep.one)
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
		let dateC = Date.distantPast

		dateA.serialize(into: &inputBuffer)
		dateB.serialize(into: &inputBuffer)
		dateC.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Date(buffer: &outputBuffer) == dateA)
		#expect(try Date(buffer: &outputBuffer) == dateB)
		#expect(try Date(buffer: &outputBuffer) == dateC)
		
		// check the encoding for ordering
		var encodedOutputBuffer = UnsafeRawBufferPointer(buffer)
		
		let intA = try Int64(buffer: &encodedOutputBuffer)
		let intB = try Int64(buffer: &encodedOutputBuffer)
		let intC = try Int64(buffer: &encodedOutputBuffer)
		
		#expect(intA > intB)
		#expect(intB > intC)
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
