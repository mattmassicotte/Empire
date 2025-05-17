import CLMDB

public enum ComparisonOperator {
	case greater(MDB_val?)
	case greaterOrEqual(MDB_val?)
	case less(MDB_val?)
	case lessOrEqual(MDB_val?)
	case range(MDB_val)
	case closedRange(MDB_val)

	public var forward: Bool {
		switch self {
		case .greater, .greaterOrEqual, .range, .closedRange:
			true
		case .less, .lessOrEqual:
			false
		}
	}
	
	public var startInclusive: Bool {
		switch self {
		case .range, .closedRange, .greaterOrEqual, .lessOrEqual:
			true
		default:
			false
		}
	}
	
	public var endInclusive: Bool {
		switch self {
		case .closedRange, .greaterOrEqual, .lessOrEqual, .greater, .less:
			true
		default:
			false
		}
	}
	
	public var endKey: MDB_val? {
		switch self {
		case let .greater(value):
			value
		case let .greaterOrEqual(value):
			value
		case let .less(value):
			value
		case let .lessOrEqual(value):
			value
		case let .range(value):
			value
		case let .closedRange(value):
			value
		}
	}
}

public struct Query {
	public let comparison: ComparisonOperator
	public let key: MDB_val
	public let limit: Int?

	public init(comparison: ComparisonOperator, key: MDB_val, limit: Int? = nil) {
		self.key = key
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
		
		return try get(key: query.key, operation: op)
	}

	private func compare(keyA: MDB_val, keyB: MDB_val) -> Int {
		var localKeyA = keyA
		var localKeyB = keyB
		let txn = mdb_cursor_txn(cursorPtr)

		return Int(mdb_cmp(txn, dbi, &localKeyA, &localKeyB))
	}
	
	/// Compare a key using the set comparision operator.
	///
	/// (included, keepGoing)
	private func check(key: MDB_val) -> (Bool, Bool) {
		let comparison = compare(keyA: key, keyB: query.key)
		
		let startInclusive = query.comparison.startInclusive
		let endInclusive = query.comparison.endInclusive
		let forward = query.comparison.forward
		if comparison < 0 && forward == true {
			return (false, true)
		}
		
		if comparison > 0 && forward == false {
			return (false, true)
		}
		
		if comparison == 0 && startInclusive == false {
			return (false, true)
		}
		
		guard let endKey = query.comparison.endKey else {
			return (true, true)
		}
		
		let endComparison = compare(keyA: key, keyB: endKey)
		
		if endComparison == 0 && endInclusive == false {
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
