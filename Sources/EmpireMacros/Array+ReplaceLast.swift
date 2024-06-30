extension Array {
	mutating func replaceLast(_ block: (Element) throws -> Element) rethrows {
		let count = self.count

		guard count > 0 else { return }

		let value = self[count - 1]

		self[count - 1] = try block(value)
	}

	func replacingLast(_ block: (Element) throws -> Element) rethrows -> Self {
		var new = self

		try new.replaceLast(block)

		return new
	}
}
