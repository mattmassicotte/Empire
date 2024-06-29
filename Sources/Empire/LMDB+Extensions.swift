import LMDB
import PackedSerialize

import CLMDB

extension MDB_val {
	init<Value: Serializable>(_ value: Value, using buffer: UnsafeMutableRawBufferPointer) {
		let size = value.serializedSize

		var localBuffer = buffer

		value.serialize(into: &localBuffer)

		self.init(mv_size: size, mv_data: buffer.baseAddress)
	}
}
