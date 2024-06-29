import CLMDB

public struct Transaction {
	var txn: OpaquePointer?
	private let env: Environment

	public init(env: Environment) throws {
		self.env = env

		try MDBError.check { mdb_txn_begin(env.internalEnv, nil, 0, &txn) }

		guard txn != nil else { throw MDBError.problem }
	}

	public static func with(env: Environment, block: (inout Transaction) throws -> Void) throws {
		var transaction = try Transaction(env: env)

		try transaction.begin()

		do {
			try block(&transaction)
			try transaction.commit()
		} catch {
			transaction.abort()

			throw error
		}
	}

	public static func with<T>(env: Environment, block: (inout Transaction) async throws -> sending T) async throws -> sending T {
		var transaction = try Transaction(env: env)

		try transaction.begin()

		do {
			let value = try await block(&transaction)
			try transaction.commit()

			return value
		} catch {
			transaction.abort()

			throw error
		}
	}

	public mutating func begin() throws {
		guard txn != nil else { throw MDBError.problem }

		try MDBError.check { mdb_txn_begin(env.internalEnv, nil, 0, &txn) }
	}

	public func commit() throws {
		try MDBError.check { mdb_txn_commit(txn) }
	}

	public func abort() {
		mdb_txn_abort(txn)
	}

	public func open(name: String) throws -> MDB_dbi {
		let dbFlags = UInt32(MDB_CREATE)
		var dbi: MDB_dbi = 0

		try name.withCString { nameStr in
			try MDBError.check { mdb_dbi_open(txn, nameStr, dbFlags, &dbi) }
		}

		return dbi
	}
}

extension Transaction {
	public func get(dbi: MDB_dbi, key: MDB_val) throws -> MDB_val {
		var localKey = key
		var localVal = MDB_val()

		try MDBError.check { mdb_get(txn, dbi, &localKey, &localVal) }

		return localVal
	}

	public func get(dbi: MDB_dbi, key: String) throws -> MDB_val {
		try key.withMDBVal { keyVal in
			try get(dbi: dbi, key: keyVal)
		}
	}

	public func getString(dbi: MDB_dbi, key: MDB_val) throws -> String {
		var localKey = key
		var localVal = MDB_val()

		try MDBError.check { mdb_get(txn, dbi, &localKey, &localVal) }

		guard let string = String(mdbVal: localVal) else {
			throw MDBError.problem
		}

		return string
	}

	public func getString(dbi: MDB_dbi, key: String) throws -> String {
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
