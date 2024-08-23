import CLMDB
import LMDB

extension Query {
	func buildLMDDBQuery(buffer: SerializationBuffer) throws -> LMDB.Query {
		switch last {
		case let .equals(value):
			let key = Tuple(repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			if let limit, limit != 1 {
				throw QueryError.limitInvalid(limit)
			}

			return LMDB.Query(comparison: .greaterOrEqual(keyVal), limit: 1)
		case let .greaterThan(value):
			let key = Tuple(repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			return LMDB.Query(comparison: .greater(keyVal), limit: limit)
		case let .greaterOrEqual(value):
			let key = Tuple(repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			return LMDB.Query(comparison: .greaterOrEqual(keyVal), limit: limit)
		case let .lessThan(value):
			let key = Tuple(repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			return LMDB.Query(comparison: .less(keyVal), limit: limit)
		case let .lessOrEqual(value):
			let key = Tuple(repeat each components, value)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)

			return LMDB.Query(comparison: .lessOrEqual(keyVal), limit: limit)
		case let .range(range):
			let key = Tuple(repeat each components, range.lowerBound)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(repeat each components, range.upperBound)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)

			return LMDB.Query(comparison: .range(keyVal, endKeyVal, inclusive: false), limit: limit)
		case let .closedRange(range):
			let key = Tuple(repeat each components, range.lowerBound)
			let keyVal = try MDB_val(key, using: buffer.keyBuffer)
			let endKey = Tuple(repeat each components, range.upperBound)
			let endKeyVal = try MDB_val(endKey, using: buffer.valueBuffer)

			return LMDB.Query(comparison: .range(keyVal, endKeyVal, inclusive: true), limit: limit)
		case .within:
			throw QueryError.unsupportedQuery
		}

	}
}
