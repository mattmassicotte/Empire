import Testing

import Empire

struct TupleTests {
	@Test func oneValueTuple() throws {
		let value = Tuple<Int>(45)

		#expect(value.elements == 45)
	}
	
	@Test func zeroValueTuple() throws {
		let value = Tuple<EmptyValue>(EmptyValue())

		#expect(value.elements == EmptyValue())
	}
}

extension TupleTests {
	@Test
	func serialize() throws {
		let value = Tuple<String, UInt>("Korben", 45)

		let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 8)

		var output = buffer

		value.serialize(into: &output)

		var input = UnsafeRawBufferPointer(start: buffer.baseAddress, count: value.serializedSize)

		let result = try Tuple<String, UInt>(buffer: &input)

		#expect(result.elements.0 == "Korben")
		#expect(result.elements.1 == 45)
	}
}

