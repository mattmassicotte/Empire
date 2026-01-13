public struct Deserializer: ~Copyable, ~Escapable, Sendable {
	private let internalRawSpan: RawSpan
	private var offset: Int

	@_lifetime(copy span)
	public init(span: RawSpan) {
		self.internalRawSpan = span
		self.offset = 0
	}

	@_lifetime(borrow buffer)
	public init(_unsafeBytes buffer: UnsafeRawBufferPointer) {
		self.init(span: buffer.bytes)
	}

	@_lifetime(borrow buffer)
	public init(_unsafeBytes buffer: UnsafeMutableRawBufferPointer) {
		self.internalRawSpan = buffer.bytes
		self.offset = 0
	}

	@_lifetime(&self)
	public mutating func unsafeLoad<T>(
		of t: T.Type,
		sized size: Int
	) throws(DeserializeError) -> T where T: BitwiseCopyable {
		try checkOffset(size)

		let value = internalRawSpan
			.extracting(offset..<offset+size)
			.unsafeLoadUnaligned(as: T.self)

		try advance(by: size)

		return value
	}

	public var rawSpan: RawSpan {
		@_lifetime(borrow self)
		borrowing get {
			internalRawSpan.extracting(droppingFirst: offset)
		}
	}

	@_lifetime(&self)
	public mutating func advance(by amount: Int) throws(DeserializeError) {
		try checkOffset(amount)

		self.offset += amount
	}

	private func checkOffset(_ value: Int) throws(DeserializeError) {
		if offset + value > internalRawSpan.byteCount {
			throw DeserializeError.endOfBufferReached(offset + value, internalRawSpan.byteCount)
		}
	}
}
