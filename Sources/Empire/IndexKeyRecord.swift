import PackedSerialize

/// Requirements for a type stored in an Empire database.
public protocol IndexKeyRecord {
	/// The `Tuple` that defines the record index key.
	associatedtype IndexKey: Serializable & Deserializable & IndexKeyComparable

	/// The `Tuple` that defines the record fields.
	associatedtype Fields: Serializable & Deserializable

	/// A prefix used for all records of the same type to distinguish them by key type alone.
	///
	/// By default, this value is the same as `keySchemaHashValue`. You can override this value to control the key prefixing strategy.
	static var keyPrefix: Int { get }

	/// An identifier used to ensure serialized data matches the record structure.
	///
	/// By default, this value is the same as `fieldSchemaHashValue`. You can override this value to use a custom field versioning strategy.
	static var fieldsVersion: Int { get }

	var indexKey: IndexKey { get }
	var fields: Fields { get }

	/// Writes out the representation of this instance into a buffer.
	///
	/// - Parameter buffer: A buffer to the seralized field data.
	func serialize(into buffer: inout SerializationBuffer)

	/// Creates a new instance from the data in a buffer.
	/// 
	/// - Parameter buffer: The buffer that holds the raw data within the backing storage.
	init(_ buffer: inout DeserializationBuffer) throws

	/// Create an instance with data that requires a migration.
	///
	/// This intializer is used if the `fieldsVersion` value in storage does not match the current value for the type. When these values do match, `init(_ buffer:)` is used instead.
	///
	/// - Parameter buffer: A buffer to the seralized field data.
	/// - Parameter version: The `fieldsVersion` value for the serialized data.
	init(_ buffer: inout DeserializationBuffer, version: Int) throws
}

extension IndexKeyRecord {
	/// Create a new instance from the data in a buffer that does not match the current schema.
	///
	/// By default, this initializer will throw `StoreError.migrationUnsupported`.
	///
	/// - Parameter buffer: The buffer that holds the raw data within the backing storage.
	/// - Parameter version: The `fieldsVersion` value corresponding to the undering raw data currently in storage.
	public init(_ buffer: inout DeserializationBuffer, version: Int) throws {
		throw Self.unsupportedMigrationError(for: version)
	}
	
	/// Create a new `StoreError.migrationUnsupported` corresponding to `Self` and the current `fieldsVersion`.
	public static func unsupportedMigrationError(for version: Int) -> StoreError {
		StoreError.migrationUnsupported(String(describing: Self.self), Self.fieldsVersion, version)
	}
}
