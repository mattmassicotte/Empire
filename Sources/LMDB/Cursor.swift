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
		case running(Int)
		case completed
	}

	private let cursorPtr: OpaquePointer
	private let dbi: MDB_dbi
	private var state = State.running(0)

	let query: Query
	
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
	
	private func get() throws -> (MDB_val, MDB_val)? {
		let comparisonOp = query.comparison
		let op = comparisonOp.forward ? MDB_NEXT : MDB_PREV
		
		return try get(key: comparisonOp.key, operation: op)
	}

	private func compare(keyA: MDB_val, keyB: MDB_val) -> Int {
		var localKeyA = keyA
		var localKeyB = keyB
		let txn = mdb_cursor_txn(cursorPtr)

		return Int(mdb_cmp(txn, dbi, &localKeyA, &localKeyB))
	}
	
	private func check(key: MDB_val) -> (Bool, Bool) {
		let comparison = compare(keyA: key, keyB: query.comparison.key)
		
		switch query.comparison {
		case .greater:
			return (comparison > 0, true)
		case .greaterOrEqual:
			return (comparison >= 0, true)
		case .less:
			return (comparison < 0, true)
		case .lessOrEqual:
			return (comparison <= 0, true)
		case let .range(_, endKey, inclusive):
			let endComparison = compare(keyA: key, keyB: endKey)
			let forward = query.comparison.forward

			if endComparison == 0 && inclusive == false {
				return (false, false)
			}

			// a < b
			if endComparison < 0 && forward == false {
				return (false, true)
			}

			// a > b
			if endComparison > 0 && forward == true {
				return (false, true)
			}

			return (true, true)
		}
	}
	
	public mutating func next() -> Element? {
		// are we still executing?
		guard case let .running(count) = state else {
			return nil
		}
		
		// have we hit our limit?
		if let limit = query.limit, count >= limit {
			self.state = .completed
			return nil
		}
		
		// do we have a valid next pair?
		guard let pair = try? get() else {
			self.state = .completed
			return nil
		}
		
		// is this value in our results?
		let (included, keepGoing) = check(key: pair.0)
		
		switch (included, keepGoing) {
		case (true, true):
			self.state = .running(count + 1)
			
			return pair
		case (true, false):
			self.state = .completed
			
			return pair
		case (false, true):
			return next()
		case (false, false):
			self.state = .completed
			
			return nil
		}
	}
}
