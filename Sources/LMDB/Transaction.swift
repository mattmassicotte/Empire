import CLMDB

public enum KeyComparisonResult {
	case descending
	case equal
	case ascending
}

public struct Transaction {
	var txn: OpaquePointer?
	private let env: Environment

	public init(env: Environment, parent: Transaction? = nil, readOnly: Bool = false) throws {
		self.env = env
		
		let flags: UInt32 = readOnly ? UInt32(MDB_RDONLY) : 0

		try MDBError.check { mdb_txn_begin(env.internalEnv.pointer, parent?.txn, flags, &txn) }

		guard txn != nil else { throw MDBError.problem }
	}

	public static func with<T>(
		env: Environment,
		parent: Transaction? = nil,
		readOnly: Bool = false,
		block: (inout Transaction) throws -> sending T
	) throws -> sending T {
		var transaction = try Transaction(env: env, parent: parent, readOnly: readOnly)

		do {
			let value = try block(&transaction)

			try Task.checkCancellation()
			try transaction.commit()

			return value
		} catch {
			transaction.abort()

			throw error
		}
	}

	public func commit() throws {
		try MDBError.check { mdb_txn_commit(txn) }
	}

	func abort() {
		mdb_txn_abort(txn)
	}

	public func open(name: String) throws -> MDB_dbi {
		let dbFlags = UInt32(MDB_CREATE)
		var dbi: MDB_dbi = 0

		try name.withCString { nameStr in
			try MDBError.check { mdb_dbi_open(txn, nameStr, dbFlags, &dbi) }
		}

		// here's where a comparator should be used...
//		try MDBError.check { mdb_set_compare(txn, dbi, comparator) }

		return dbi
	}
}

extension Transaction {
	public func get(dbi: MDB_dbi, key: MDB_val) throws -> MDB_val? {
		var localKey = key
		var localVal = MDB_val()

		let result = mdb_get(txn, dbi, &localKey, &localVal)
		switch result {
		case 0:
			break
		case MDB_NOTFOUND:
			return nil
		default:
			throw MDBError(result)
		}

		return localVal
	}

	public func get(dbi: MDB_dbi, key: String) throws -> MDB_val? {
		try key.withMDBVal { keyVal in
			try get(dbi: dbi, key: keyVal)
		}
	}

	public func getString(dbi: MDB_dbi, key: MDB_val) throws -> String? {
		guard let localVal = try get(dbi: dbi, key: key) else {
			return nil
		}

		guard let string = String(mdbVal: localVal) else {
			throw MDBError.problem
		}

		return string
	}

	public func getString(dbi: MDB_dbi, key: String) throws -> String? {
		try key.withMDBVal { keyVal in
			try getString(dbi: dbi, key: keyVal)
		}
	}
}

extension Transaction {
	public func set(dbi: MDB_dbi, key: MDB_val, value: MDB_val) throws  {
		let flags = UInt32(0)
		var localKey = key
		var localValue = value

		try MDBError.check { mdb_put(txn, dbi, &localKey, &localValue, flags) }
	}

	public func set(dbi: MDB_dbi, keyBuffer: UnsafeRawBufferPointer, valueBuffer: UnsafeRawBufferPointer) throws  {
		let flags = UInt32(0)
		var localKey = MDB_val(buffer: keyBuffer)
		var localValue = MDB_val(buffer: valueBuffer)

		try MDBError.check { mdb_put(txn, dbi, &localKey, &localValue, flags) }
	}

	public func set(dbi: MDB_dbi, key: String, value: MDB_val) throws {
		try key.withMDBVal { keyVal in
			try set(dbi: dbi, key: keyVal, value: value)
		}
	}

	public func set(dbi: MDB_dbi, key: String, value: String) throws {
		try value.withMDBVal { valueVal in
			try set(dbi: dbi, key: key, value: valueVal)
		}
	}
}

extension Transaction {
	public func delete(dbi: MDB_dbi, key: MDB_val) throws {
		var localKey = key
		var localVal = MDB_val()

		try MDBError.check { mdb_del(txn, dbi, &localKey, &localVal) }
	}

	public func delete(dbi: MDB_dbi, key: String) throws {
		try key.withMDBVal { keyVal in
			try delete(dbi: dbi, key: keyVal)
		}
	}
}

extension Transaction {
	@_lifetime(borrow self)
	func get(dbi: MDB_dbi, key: RawSpan) throws -> RawSpan? {
		var localKey = MDB_val(key)
		var localVal = MDB_val()

		let result = mdb_get(txn, dbi, &localKey, &localVal)
		switch result {
		case 0:
			break
		case MDB_NOTFOUND:
			return nil
		default:
			throw MDBError(result)
		}

		return _overrideLifetime(localVal.span, borrowing: self)
	}

	func set(dbi: MDB_dbi, key: RawSpan, value: RawSpan) throws  {
		let flags = UInt32(0)
		var localKey = MDB_val(key)
		var localValue = MDB_val(value)

		try MDBError.check { mdb_put(txn, dbi, &localKey, &localValue, flags) }
	}
}
