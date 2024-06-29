import CLMDB

public enum CursorOperation: Hashable, Sendable {
	case next
	case previous
	case setRange
	case setKey

	var cursorOp: MDB_cursor_op {
		switch self {
		case .next: MDB_NEXT
		case .previous: MDB_PREV
		case .setRange: MDB_SET_RANGE
		case .setKey: MDB_SET_KEY
		}
	}
}

public struct Cursor {
	let cursorPtr: OpaquePointer

	public init(transaction: Transaction, dbi: MDB_dbi) throws {
		var ptr: OpaquePointer? = nil
		try MDBError.check { mdb_cursor_open(transaction.txn, dbi, &ptr) }

		guard let ptr else {
			throw MDBError.problem
		}

		self.cursorPtr = ptr
	}

	public func close() {
		mdb_cursor_close(cursorPtr)
	}

	public func get(key: MDB_val, _ operation: CursorOperation) throws -> (MDB_val, MDB_val)? {
		var localKey = key
		var value = MDB_val()

		let result = mdb_cursor_get(cursorPtr, &localKey, &value, operation.cursorOp)
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
}

extension Cursor {
	public func getRange(startingAt: MDB_val, forwards: Bool, predicate: ((MDB_val, MDB_val)) throws -> Bool) throws {
		guard var pair = try get(key: startingAt, .setRange) else {
			return
		}

		let op: CursorOperation = forwards ? .next : .previous

		while try predicate(pair) {
			guard let subsequent = try get(key: startingAt, op) else {
				return
			}

			pair = subsequent
		}
	}
}
