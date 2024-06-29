import CLMDB

extension String {
	public init?(mdbVal: MDB_val) {
		let ptr = mdbVal.mv_data.assumingMemoryBound(to: UInt8.self)
		let buffer = UnsafeBufferPointer(start: ptr, count: mdbVal.mv_size)

		self.init(bytes: buffer, encoding: String.Encoding.utf8)
	}

	public func withMDBVal<T>(_ block: (MDB_val) throws -> T) rethrows -> T {
		try withCString { cStr in
			let unsafePtr = UnsafeMutableRawPointer(mutating: cStr)
			let value = MDB_val(mv_size: utf8.count, mv_data: unsafePtr)

			return try block(value)
		}
	}
}
