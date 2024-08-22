import LMDB
import PackedSerialize

import CLMDB

extension MDB_val {
	init<Value: Serializable>(_ value: Value, using buffer: UnsafeMutableRawBufferPointer) throws {
		let size = value.serializedSize

		guard size <= buffer.count else {
			throw StoreError.keyBufferOverflow
		}

		var localBuffer = buffer

		value.serialize(into: &localBuffer)

		self.init(mv_size: size, mv_data: buffer.baseAddress)
	}
}
