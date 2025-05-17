import CLMDB
import LMDB

extension Query {
	func buildLMDDBQuery(buffer: SerializationBuffer, prefix: some Serializable & IndexKeyComparable) throws -> LMDB.Query {
		switch last {
		case let .equals(value):
			let key = Tuple(prefix, repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			return LMDB.Query(comparison: .greaterOrEqual(nil), key: keyVal, limit: limit)
		case let .greaterThan(value):
			let key = Tuple(prefix, repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			return LMDB.Query(comparison: .greater(nil), key: keyVal, limit: limit)
		case let .greaterOrEqual(value):
			let key = Tuple(prefix, repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			return LMDB.Query(comparison: .greaterOrEqual(nil), key: keyVal, limit: limit)
		case let .lessThan(value):
			let key = Tuple(prefix, repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			return LMDB.Query(comparison: .less(nil), key: keyVal, limit: limit)
		case let .lessOrEqual(value):
			let key = Tuple(prefix, repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			return LMDB.Query(comparison: .lessOrEqual(nil), key: keyVal, limit: limit)
		case let .range(range):
			let key = Tuple(prefix, repeat each components, range.lowerBound)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(prefix, repeat each components, range.upperBound)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)

			return LMDB.Query(comparison: .range(endKeyVal), key: keyVal, limit: limit)
		case let .closedRange(range):
			let key = Tuple(prefix, repeat each components, range.lowerBound)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(prefix, repeat each components, range.upperBound)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)

			return LMDB.Query(comparison: .closedRange(endKeyVal), key: keyVal, limit: limit)
		case .within:
			throw QueryError.unsupportedQuery
		}

	}
}
