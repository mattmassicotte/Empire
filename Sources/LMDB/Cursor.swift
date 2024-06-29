import CLMDB

public enum CursorOperation: Hashable, Sendable {
	case next
	case setRange
	case setKey

	var cursorOp: MDB_cursor_op {
		switch self {
		case .next: MDB_NEXT
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

	public func get(key: MDB_val, _ operation: CursorOperation) throws -> (MDB_val, MDB_val) {
		var localKey = key
		var value = MDB_val()

		try MDBError.check { mdb_cursor_get(cursorPtr, &localKey, &value, operation.cursorOp) }

		return (localKey, value)
	}
}

