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

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try UInt.unpack(with: &deserialier) == a)
		#expect(try UInt.unpack(with: &deserialier) == b)
		#expect(try UInt.unpack(with: &deserialier) == c)
		#expect(try UInt.unpack(with: &deserialier) == d)

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

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try Int.unpack(with: &deserialier) == a)
		#expect(try Int.unpack(with: &deserialier) == b)
		#expect(try Int.unpack(with: &deserialier) == c)
		#expect(try Int.unpack(with: &deserialier) == d)
		#expect(try Int.unpack(with: &deserialier) == e)
		#expect(try Int.unpack(with: &deserialier) == f)
		#expect(try Int.unpack(with: &deserialier) == g)
		#expect(try Int.unpack(with: &deserialier) == h)

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

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try Int64.unpack(with: &deserialier) == a)
		#expect(try Int64.unpack(with: &deserialier) == b)
		#expect(try Int64.unpack(with: &deserialier) == c)
		#expect(try Int64.unpack(with: &deserialier) == d)
		#expect(try Int64.unpack(with: &deserialier) == e)
		#expect(try Int64.unpack(with: &deserialier) == f)
		#expect(try Int64.unpack(with: &deserialier) == g)
		#expect(try Int64.unpack(with: &deserialier) == h)

		#expect([a,b,c,d,e,f,g,h].sorted() == [h,g,f,e,d,c,b,a])
		#expect(ComparableData.sort([a,b,c,d,e,f,g,h]) == [h,g,f,e,d,c,b,a])
	}

	@Test func serializeUInt8() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		UInt8(42).serialize(into: &inputBuffer)
		UInt8(142).serialize(into: &inputBuffer)
		UInt8(0).serialize(into: &inputBuffer)

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try UInt8.unpack(with: &deserialier) == 42)
		#expect(try UInt8.unpack(with: &deserialier) == 142)
		#expect(try UInt8.unpack(with: &deserialier) == 0)
	}
	
	@Test func serializeString() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		let a = "ddd"
		let b = "cccc"
		let c = "ccc"
		let d = "cca"
		let e = "bcc"
		let f = "acc"
		let g = "aaa"
		let h = "aa"
		let i = ""

		a.serialize(into: &inputBuffer)
		b.serialize(into: &inputBuffer)
		c.serialize(into: &inputBuffer)
		d.serialize(into: &inputBuffer)
		e.serialize(into: &inputBuffer)
		f.serialize(into: &inputBuffer)
		g.serialize(into: &inputBuffer)
		h.serialize(into: &inputBuffer)
		i.serialize(into: &inputBuffer)

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try String.unpack(with: &deserialier) == a)
		#expect(try String.unpack(with: &deserialier) == b)
		#expect(try String.unpack(with: &deserialier) == c)
		#expect(try String.unpack(with: &deserialier) == d)
		#expect(try String.unpack(with: &deserialier) == e)
		#expect(try String.unpack(with: &deserialier) == f)
		#expect(try String.unpack(with: &deserialier) == g)
		#expect(try String.unpack(with: &deserialier) == h)
		#expect(try String.unpack(with: &deserialier) == i)

		#expect([a,b,c,d,e,f,g,h,i].sorted() == [i,h,g,f,e,d,c,b,a])
		#expect(ComparableData.sort([a,b,c,d,e,f,g,h,i]) == [i,h,g,f,e,d,c,b,a])
	}

	@Test func serializeBoolString() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		true.serialize(into: &inputBuffer)
		false.serialize(into: &inputBuffer)

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try Bool.unpack(with: &deserialier) == true)
		#expect(try Bool.unpack(with: &deserialier) == false)
	}
	
	@Test func deserializeBoolWithInvalidValue() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		UInt8(4).serialize(into: &inputBuffer)

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(throws: DeserializeError.invalidValue, performing: {
			try Bool.unpack(with: &deserialier)
		})
	}
	
	@Test func serializeOptionalString() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		Optional<String>.some("hello").serialize(into: &inputBuffer)
		Optional<String>.some("goodbye").serialize(into: &inputBuffer)

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try String?.unpack(with: &deserialier) == "hello")
		#expect(try String?.unpack(with: &deserialier) == "goodbye")
	}
	
	@Test func serializeStringArray() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		["1", "2", "3"].serialize(into: &inputBuffer)

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try [String].unpack(with: &deserialier) == ["1", "2", "3"])
	}
	
	@Test func rawRepresentable() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		HasRawRep.two.serialize(into: &inputBuffer)
		HasRawRep.one.serialize(into: &inputBuffer)

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try HasRawRep.unpack(with: &deserialier) == HasRawRep.two)
		#expect(try HasRawRep.unpack(with: &deserialier) == HasRawRep.one)
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

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try UUID.unpack(with: &deserialier) == uuidA)
		#expect(try UUID.unpack(with: &deserialier) == uuidB)
	}

	@Test func serializeData() throws {
		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)
		var inputBuffer = buffer

		let dataA = Data([1,2,3,4])
		let dataB = Data([0xfa, 0xdb, 0xcc, 0xbd])

		dataA.serialize(into: &inputBuffer)
		dataB.serialize(into: &inputBuffer)

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try Data.unpack(with: &deserialier) == dataA)
		#expect(try Data.unpack(with: &deserialier) == dataB)
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

		var deserialier = Deserializer(_unsafeBytes: buffer)

		#expect(try Date.unpack(with: &deserialier) == a)
		#expect(try Date.unpack(with: &deserialier) == b)
		#expect(try Date.unpack(with: &deserialier) == c)
		#expect(try Date.unpack(with: &deserialier) == d)

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
