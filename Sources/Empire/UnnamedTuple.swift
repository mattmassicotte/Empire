public struct UnnamedTuple<each Element> {
	public let elements: (repeat each Element)

	public init(_ value: repeat each Element) {
		self.elements = (repeat each value)
	}
}

extension UnnamedTuple: Equatable where repeat each Element: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		for (left, right) in repeat (each lhs.elements, each rhs.elements) {
			guard left == right else {
				return false
			}
		}

		return true
	}
}

extension UnnamedTuple: Hashable where repeat each Element: Hashable {
	public func hash(into hasher: inout Hasher) {
		for element in repeat each elements {
			element.hash(into: &hasher)
		}
	}
}
