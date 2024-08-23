import CLMDB

public enum ComparisonOperator {
	case greater(MDB_val)
	case greaterOrEqual(MDB_val)
	case less(MDB_val)
	case lessOrEqual(MDB_val)
	case range(MDB_val, MDB_val, inclusive: Bool = false)

	public var key: MDB_val {
		switch self {
		case let .greater(key):
			key
		case let .greaterOrEqual(key):
			key
		case let .less(key):
			key
		case let .lessOrEqual(key):
			key
		case let .range(start, _, _):
			start
		}
	}

	public var forward: Bool {
		switch self {
		case .greater, .greaterOrEqual, .range:
			true
		case .less, .lessOrEqual:
			false
		}
	}
}

public struct Query {
	public let comparison: ComparisonOperator
	public let limit: Int?

	public init(comparison: ComparisonOperator, limit: Int? = nil) {
		self.comparison = comparison
		self.limit = limit
	}
}

public struct Cursor: Sequence, IteratorProtocol {
	public typealias Element = (MDB_val, MDB_val)

	private enum State: Hashable {
		case notStarted
		case started(Int)
		case completed
	}

	private let cursorPtr: OpaquePointer
	private let dbi: MDB_dbi
	let query: Query
	private var state = State.notStarted

	public init(transaction: Transaction, dbi: MDB_dbi, query: Query) throws {
		var ptr: OpaquePointer? = nil
		try MDBError.check { mdb_cursor_open(transaction.txn, dbi, &ptr) }

		guard let ptr else {
			throw MDBError.problem
		}

		self.dbi = dbi
		self.cursorPtr = ptr
		self.query = query
	}

	public func close() {
		mdb_cursor_close(cursorPtr)
	}

	private func get(key: MDB_val, operation: MDB_cursor_op) throws -> (MDB_val, MDB_val)? {
		var localKey = key
		var value = MDB_val()

		let result = mdb_cursor_get(cursorPtr, &localKey, &value, operation)
		switch result {
		case 0:
			break
		case MDB_NOTFOUND:
			return nil
		default:
			throw MDBError(result)
		}

		return (localKey, value)
	}

	private func compare(keyA: MDB_val, keyB: MDB_val) -> Int {
		var localKeyA = keyA
		var localKeyB = keyB
		let txn = mdb_cursor_txn(cursorPtr)

		return Int(mdb_cmp(txn, dbi, &localKeyA, &localKeyB))
	}

	private func endConditionReached(key: MDB_val) -> Bool {
		let op = query.comparison

		guard case let .range(_, endKey, inclusive) = op else {
			return false
		}

		let comparison = compare(keyA: key, keyB: endKey)

		if comparison == 0 && inclusive == false {
			return true
		}

		// a < b
		if comparison < 0 && op.forward == false {
			return true
		}

		// a > b
		if comparison > 0 && op.forward == true {
			return true
		}

		return false
	}

	public mutating func next() -> Element? {
		let comparisonOp = query.comparison

		do {
			switch state {
			case .completed:
				break
			case .notStarted:
				let initial = try get(key: comparisonOp.key, operation: MDB_SET_RANGE)

				switch comparisonOp {
				case .less, .greater:
					self.state = .started(0)
					return next()
				case .greaterOrEqual, .lessOrEqual, .range:
					self.state = .started(1)
					return initial
				}
			case let .started(count):
				if let limit = query.limit, count == limit {
					self.state = .completed
					break
				}

				let op = comparisonOp.forward ? MDB_NEXT : MDB_PREV

				guard let pair = try get(key: comparisonOp.key, operation: op) else {
					self.state = .completed
					break
				}

				if endConditionReached(key: pair.0) {
					self.state = .completed
					break
				}

				self.state = .started(count + 1)

				return pair
			}
		} catch {
			self.state = .completed
		}

		return nil
	}
}
