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

		let a = UInt.max
		let b = UInt(142)
		let c = UInt(42)
		let d = UInt.min
		
		a.serialize(into: &inputBuffer)
		b.serialize(into: &inputBuffer)
		c.serialize(into: &inputBuffer)
		d.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try UInt(buffer: &outputBuffer) == a)
		#expect(try UInt(buffer: &outputBuffer) == b)
		#expect(try UInt(buffer: &outputBuffer) == c)
		#expect(try UInt(buffer: &outputBuffer) == d)
		
		#expect([a,b,c,d].sorted() == [d,c,b,a])
		#expect(ComparableData.sort([a,b,c,d]) == [d,c,b,a])
	}

	@Test func serializeInt() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		let a = Int.max
		let b = Int(142)
		let c = Int(42)
		let d = Int(0)
		let e = Int(-1)
		let f = Int(-42)
		let g = Int(Int.min + 1)
		let h = Int.min

		a.serialize(into: &inputBuffer)
		b.serialize(into: &inputBuffer)
		c.serialize(into: &inputBuffer)
		d.serialize(into: &inputBuffer)
		e.serialize(into: &inputBuffer)
		f.serialize(into: &inputBuffer)
		g.serialize(into: &inputBuffer)
		h.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Int(buffer: &outputBuffer) == a)
		#expect(try Int(buffer: &outputBuffer) == b)
		#expect(try Int(buffer: &outputBuffer) == c)
		#expect(try Int(buffer: &outputBuffer) == d)
		#expect(try Int(buffer: &outputBuffer) == e)
		#expect(try Int(buffer: &outputBuffer) == f)
		#expect(try Int(buffer: &outputBuffer) == g)
		#expect(try Int(buffer: &outputBuffer) == h)
		
		#expect([a,b,c,d,e,f,g,h].sorted() == [h,g,f,e,d,c,b,a])
		#expect(ComparableData.sort([a,b,c,d,e,f,g,h]) == [h,g,f,e,d,c,b,a])
	}
	
	@Test func serializeInt64() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		let a = Int64.max
		let b = Int64(142)
		let c = Int64(42)
		let d = Int64(0)
		let e = Int64(-1)
		let f = Int64(-42)
		let g = Int64(Int64.min + 1)
		let h = Int64.min
		
		a.serialize(into: &inputBuffer)
		b.serialize(into: &inputBuffer)
		c.serialize(into: &inputBuffer)
		d.serialize(into: &inputBuffer)
		e.serialize(into: &inputBuffer)
		f.serialize(into: &inputBuffer)
		g.serialize(into: &inputBuffer)
		h.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Int64(buffer: &outputBuffer) == a)
		#expect(try Int64(buffer: &outputBuffer) == b)
		#expect(try Int64(buffer: &outputBuffer) == c)
		#expect(try Int64(buffer: &outputBuffer) == d)
		#expect(try Int64(buffer: &outputBuffer) == e)
		#expect(try Int64(buffer: &outputBuffer) == f)
		#expect(try Int64(buffer: &outputBuffer) == g)
		#expect(try Int64(buffer: &outputBuffer) == h)
		
		#expect([a,b,c,d,e,f,g,h].sorted() == [h,g,f,e,d,c,b,a])
		#expect(ComparableData.sort([a,b,c,d,e,f,g,h]) == [h,g,f,e,d,c,b,a])
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

		let a = "cccc"
		let b = "ccc"
		let c = "cca"
		let d = "bcc"
		let e = "acc"
		let f = "aa"
		let g = ""

		a.serialize(into: &inputBuffer)
		b.serialize(into: &inputBuffer)
		c.serialize(into: &inputBuffer)
		d.serialize(into: &inputBuffer)
		e.serialize(into: &inputBuffer)
		f.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try String(buffer: &outputBuffer) == a)
		#expect(try String(buffer: &outputBuffer) == b)
		#expect(try String(buffer: &outputBuffer) == c)
		#expect(try String(buffer: &outputBuffer) == d)
		#expect(try String(buffer: &outputBuffer) == e)
		#expect(try String(buffer: &outputBuffer) == f)
		#expect(try String(buffer: &outputBuffer) == g)

		#expect([a,b,c,d,e,f,g].sorted() == [g,f,e,d,c,b,a])
		#expect(ComparableData.sort([a,b,c,d,e,f,g]) == [g,f,e,d,c,b,a])
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
		let a = Date(timeIntervalSince1970:Date.now.timeIntervalSince1970.rounded(.down))
		let b = Date(timeIntervalSince1970: 0.0)
		let c = Date(timeIntervalSince1970: -1.0)
		let d = Date.distantPast

		a.serialize(into: &inputBuffer)
		b.serialize(into: &inputBuffer)
		c.serialize(into: &inputBuffer)
		d.serialize(into: &inputBuffer)

		var outputBuffer = UnsafeRawBufferPointer(buffer)

		#expect(try Date(buffer: &outputBuffer) == a)
		#expect(try Date(buffer: &outputBuffer) == b)
		#expect(try Date(buffer: &outputBuffer) == c)
		#expect(try Date(buffer: &outputBuffer) == d)
		
		// check the encoding for ordering
		#expect([a,b,c,d].sorted() == [d,c,b,a])
		#expect(ComparableData.sort([a,b,c,d]) == [d,c,b,a])
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
