import PackedSerialize

/// A static collection of values.
public struct Tuple<each Element> {
	public let elements: (repeat each Element)

	public init(_ value: repeat each Element) {
		self.elements = (repeat each value)
	}
}

extension Tuple: Equatable where repeat each Element: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		for (left, right) in repeat (each lhs.elements, each rhs.elements) {
			guard left == right else {
				return false
			}
		}

		return true
	}
}

extension Tuple: Hashable where repeat each Element: Hashable {
	public func hash(into hasher: inout Hasher) {
		for element in repeat each elements {
			element.hash(into: &hasher)
		}
	}
}

extension Tuple: Sendable where repeat each Element: Sendable {
}

extension Tuple: Serializable where repeat each Element: Serializable {
	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		for element in repeat each elements {
			element.serialize(into: &buffer)
		}
	}

	public var serializedSize: Int {
		var length = 0

		for element in repeat each elements {
			length += element.serializedSize
		}

		return length
	}
}

extension Tuple: Deserializable where repeat each Element: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		self.elements = (repeat try (each Element).init(buffer: &buffer))
	}
}

extension Tuple: Comparable where repeat each Element: Comparable {
	public static func < (lhs: Tuple<repeat each Element>, rhs: Tuple<repeat each Element>) -> Bool {
		for (left, right) in repeat (each lhs.elements, each rhs.elements) {
			guard left < right else {
				return false
			}
		}

		return true
	}
}

extension Tuple: IndexKeyComparable where repeat each Element: IndexKeyComparable {

}

extension Tuple: CustomStringConvertible where repeat each Element: CustomStringConvertible {
	public var description: String {
		var strings = [String]()

		for element in repeat each elements {
			strings.append(element.description)
		}

		return "(" + strings.joined(separator: ", ") + ")"
	}
}

extension Tuple: CloudKitRecordNameRepresentable where repeat each Element: CustomStringConvertible {
	public var ckRecordName: String {
		var string = ""

		for element in repeat each elements {
			string += element.description
		}

		return string
	}
}
