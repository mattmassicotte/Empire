import CLMDB

extension MDB_val {
	public init(buffer: UnsafeMutableRawBufferPointer) {
		self.init(mv_size: buffer.count, mv_data: buffer.baseAddress)
	}

	public init(buffer: UnsafeRawBufferPointer) {
		let unsafePtr = UnsafeMutableRawPointer(mutating: buffer.baseAddress)

		self.init(mv_size: buffer.count, mv_data: unsafePtr)
	}

	public var bufferPointer: UnsafeRawBufferPointer {
		UnsafeRawBufferPointer(start: mv_data, count: mv_size)
	}
	
	func truncated(to size: Int) -> MDB_val? {
		if mv_size < size {
			return nil
		}

		return MDB_val(mv_size: size, mv_data: mv_data)
	}
}

#if hasFeature(Lifetimes)
extension MDB_val {
	var span: Span<UInt8> {
		@_lifetime(borrow self)
		borrowing get {
			let ptr = mv_data.assumingMemoryBound(to: UInt8.self)
			let span = Span(_unsafeStart: ptr, count: mv_size)

			return _overrideLifetime(span, borrowing: self)
		}
	}

	@_lifetime(borrow span)
	init(_ span: Span<UInt8>) {
		let val = span.withUnsafeBytes { buffer in
			let unsafePtr = UnsafeMutableRawPointer(mutating: buffer.baseAddress)

			return MDB_val(mv_size: buffer.count, mv_data: unsafePtr)
		}

		self = val
	}
}
#endif
