@_exported
import PackedSerialize

/// Adds conformance to the `IndexKeyRecord` protocol and associated query functions.
@attached(
	extension,
	conformances: IndexKeyRecord,
	names:
		named(IndexKey),
		named(Fields),
		named(indexKey),
		named(fields),
		named(serialize),
		named(deserialize(with:)),
		named(fieldsVersion),
		named(keyPrefix),
		named(select),
		named(delete)
)
public macro IndexKeyRecord(
	validated: Int? = nil,
	keyPrefix: Int? = nil,
	fieldsVersion: Int? = nil,
	_ first: StaticString,
	_ remaining: StaticString...
) = #externalMacro(module: "EmpireMacros", type: "IndexKeyRecordMacro")

#if canImport(CloudKit)
/// Adds conformance to the `CloudKitRecord` protocol.
@attached(
	extension,
	conformances: CloudKitRecord,
	names:
		named(ckRecord),
		named(init)
)
public macro CloudKitRecord() = #externalMacro(module: "EmpireMacros", type: "CloudKitRecordMacro")
#endif
