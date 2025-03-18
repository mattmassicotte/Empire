import PackedSerialize

/// Requirements for a type stored in an Empire database.
public protocol IndexKeyRecord {
	associatedtype IndexKey: Serializable & Deserializable & IndexKeyComparable
	associatedtype Fields: Serializable & Deserializable

	static var keyPrefix: Int { get }
	static var fieldsVersion: Int { get }

	var fieldsSerializedSize: Int { get }
	var indexKey: IndexKey { get }

	func serialize(into buffer: inout SerializationBuffer)
	init(_ buffer: inout DeserializationBuffer) throws

	/// Create an instance with data that requires a migration.
	init(_ buffer: inout DeserializationBuffer, version: Int) throws
}

extension IndexKeyRecord {
	public init(_ buffer: inout DeserializationBuffer, version: Int) throws {
		throw Self.unsupportedMigrationError(for: version)
	}
	
	public static func unsupportedMigrationError(for version: Int) -> StoreError {
		StoreError.migrationUnsupported(String(describing: Self.self), Self.fieldsVersion, version)
	}
}
