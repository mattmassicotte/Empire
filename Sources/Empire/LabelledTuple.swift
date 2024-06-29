/// A static collection of name-value pairs.
public struct LabelledTuple<each Element> {
	public let elements: (repeat (name: String, value: each Element))

	public init(_ value: repeat (String, each Element)) {
		self.elements = (repeat each value)
	}
}

extension LabelledTuple: Equatable where repeat each Element: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		for (left, right) in repeat (each lhs.elements, each rhs.elements) {
			guard left == right else {
				return false
			}
		}

		return true
	}
}

extension LabelledTuple: Comparable where repeat each Element: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		for (left, right) in repeat (each lhs.elements, each rhs.elements) {
			guard left < right else {
				return false
			}
		}

		return true
	}
}

extension LabelledTuple: Hashable where repeat each Element: Hashable {
	public func hash(into hasher: inout Hasher) {
		for element in repeat each elements {
			element.name.hash(into: &hasher)
			element.value.hash(into: &hasher)
		}
	}
}

extension LabelledTuple: Sendable where repeat each Element: Sendable {
}
