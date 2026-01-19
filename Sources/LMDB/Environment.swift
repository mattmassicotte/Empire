import CLMDB

public enum MDBError: Error, Hashable {
	case problem
	case recordNotFound
	case permissionDenied
	case failure(Int, String)

	init(_ result: Int32) {
		let string = String(cString: mdb_strerror(result))

		self = MDBError.failure(Int(result), string)
	}

	static func check(_ operation: () throws -> Int32) throws {
		let result = try operation()

		switch result {
		case 0:
			return
		case MDB_NOTFOUND:
			throw MDBError.recordNotFound
		case EACCES:
			throw MDBError.permissionDenied
		default:
			throw MDBError(result)
		}
	}
}

struct SendableOpaquePointer: @unchecked Sendable {
	let pointer: OpaquePointer
}

public final class Environment: Sendable {
	let internalEnv: SendableOpaquePointer

	public init() throws {
		var ptr: OpaquePointer? = nil

		try MDBError.check { mdb_env_create(&ptr) }

		guard let ptr else { throw MDBError.problem }

		self.internalEnv = SendableOpaquePointer(pointer: ptr)
	}

	public convenience init(path: String, maxDatabases: Int? = nil, locking: Bool = true) throws {
		try self.init()

		if let max = maxDatabases {
			try setMaxDatabases(max)
		}

		// this is totally arbitrary and should be better tuned
		try setMaxDatabaseSize(4096*4096*16)

		try open(path: path, locking: locking)
	}

	deinit {
		mdb_env_close(internalEnv.pointer)
	}

	public func setMaxDatabaseSize(_ value: Int) throws {
		try MDBError.check { mdb_env_set_mapsize(internalEnv.pointer, value) }
	}

	public func setMaxDatabases(_ value: Int) throws {
		try MDBError.check { mdb_env_set_maxdbs(internalEnv.pointer, UInt32(value)) }
	}

	private func open(path: String, locking: Bool) throws {
		let envFlags = UInt32(MDB_NOTLS) | (locking ? 0 : UInt32(MDB_NOLOCK))
		let envMode: mdb_mode_t = S_IRUSR | S_IWUSR

		try path.withCString { pathStr in
			try MDBError.check { mdb_env_open(internalEnv.pointer, pathStr, envFlags, envMode) }
		}
	}

	public var path: String {
		var str: UnsafePointer<Int8>? = nil

		guard
			mdb_env_get_path(internalEnv.pointer, &str) == 0,
			let str
		else {
			return ""
		}

		return String(cString: str)
	}

	public var maximumKeySize: Int {
		Int(mdb_env_get_maxkeysize(internalEnv.pointer))
	}
}

#if canImport(Foundation)
import Foundation

extension Environment {
	public convenience init(url: URL, maxDatabases: Int? = nil, locking: Bool = true) throws {
		try self.init(path: url.path, maxDatabases: maxDatabases, locking: locking)
	}
}
#endif

