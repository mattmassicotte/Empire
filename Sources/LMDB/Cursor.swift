import CLMDB

public struct Cursor: Sequence, IteratorProtocol {
	public typealias Element = (MDB_val, MDB_val)

	public struct Query {
		public let key: MDB_val
		public let forward: Bool
		public let endKey: (MDB_val, inclusive: Bool)?

		public init(key: MDB_val, forward: Bool, endKey: MDB_val, inclusive: Bool) {
			self.key = key
			self.forward = forward
			self.endKey = (endKey, inclusive)
		}

		public init(key: MDB_val, forward: Bool = true) {
			self.key = key
			self.forward = forward
			self.endKey = nil
		}
	}

	private enum State: Hashable {
		case notStarted
		case started
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
		guard let ending = query.endKey else {
			return false
		}

		let comparison = compare(keyA: key, keyB: ending.0)

		if comparison == 0 && ending.1 == false {
			return true
		}

		// a < b
		if comparison < 0 && query.forward == false {
			return true
		}

		// a > b
		if comparison > 0 && query.forward == true {
			return true
		}

		return false
	}

	public mutating func next() -> Element? {
		do {
			switch state {
			case .completed:
				break
			case .notStarted:
				self.state = .started

				return try get(key: query.key, operation: MDB_SET_RANGE)
			case .started:
				let op = query.forward ? MDB_NEXT : MDB_PREV

				guard let pair = try get(key: query.key, operation: op) else {
					self.state = .completed
					break
				}

				if endConditionReached(key: pair.0) {
					self.state = .completed
					break
				}

				return pair
			}
		} catch {
			self.state = .completed
		}

		return nil
	}
}
