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

	init<Value: Serializable, Prefix: Serializable>(_ value: Value, prefix: Prefix, using buffer: UnsafeMutableRawBufferPointer) throws {
		let size = value.serializedSize + prefix.serializedSize

		guard size <= buffer.count else {
			throw StoreError.keyBufferOverflow
		}

		var localBuffer = buffer

		prefix.serialize(into: &localBuffer)
		value.serialize(into: &localBuffer)

		self.init(mv_size: size, mv_data: buffer.baseAddress)
	}
}
