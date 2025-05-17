import CLMDB
import LMDB

extension Query {
	func buildLMDDBQuery(buffer: SerializationBuffer, prefix: some Serializable & IndexKeyComparable) throws -> LMDB.Query {
		switch last {
		case let .greaterThan(value):
			let key = Tuple(prefix, repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(prefix, repeat each components)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)
			
			return LMDB.Query(comparison: .greater(endKeyVal), key: keyVal, limit: limit, truncating: true)
		case let .greaterOrEqual(value):
			let key = Tuple(prefix, repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(prefix, repeat each components)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)

			return LMDB.Query(comparison: .greaterOrEqual(endKeyVal), key: keyVal, limit: limit, truncating: true)
		case let .lessThan(value):
			let key = Tuple(prefix, repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(prefix, repeat each components)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)

			return LMDB.Query(comparison: .less(endKeyVal), key: keyVal, limit: limit, truncating: true)
		case let .lessOrEqual(value):
			let key = Tuple(prefix, repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(prefix, repeat each components)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)

			return LMDB.Query(comparison: .lessOrEqual(endKeyVal), key: keyVal, limit: limit, truncating: true)
		case let .range(range):
			let key = Tuple(prefix, repeat each components, range.lowerBound)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(prefix, repeat each components, range.upperBound)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)

			return LMDB.Query(comparison: .range(endKeyVal), key: keyVal, limit: limit, truncating: true)
		case let .closedRange(range):
			let key = Tuple(prefix, repeat each components, range.lowerBound)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(prefix, repeat each components, range.upperBound)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)

			return LMDB.Query(comparison: .closedRange(endKeyVal), key: keyVal, limit: limit, truncating: true)
		case .within:
			throw QueryError.unsupportedQuery
		}
	}
}
