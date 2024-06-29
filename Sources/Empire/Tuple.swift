/// A collection of name-value pairs with a length known at compile time.
public struct Tuple<each Element> {
	public let elements: (repeat (name: String, value: each Element))

	public init(_ value: repeat (String, each Element)) {
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

extension Tuple: Comparable where repeat each Element: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		for (left, right) in repeat (each lhs.elements, each rhs.elements) {
			guard left < right else {
				return false
			}
		}

		return true
	}
}

extension Tuple: Hashable where repeat each Element: Hashable {
	public func hash(into hasher: inout Hasher) {
		for element in repeat each elements {
			element.name.hash(into: &hasher)
			element.value.hash(into: &hasher)
		}
	}
}

extension Tuple: Sendable where repeat each Element: Sendable {
}
