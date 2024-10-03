@_exported
import PackedSerialize

@attached(
	extension,
	conformances: IndexKeyRecord,
	names:
		named(IndexKey),
		named(Fields),
		named(fieldsSerializedSize),
		named(indexKey),
		named(serialize),
		named(init),
		named(fieldsVersion),
		named(keyPrefix),
		named(select)
)
public macro IndexKeyRecord(
	_ first: StaticString,
	_ remaining: StaticString...
) = #externalMacro(module: "EmpireMacros", type: "IndexKeyRecordMacro")

#if canImport(CloudKit)
@attached(
	extension,
	conformances: CloudKitRecord,
	names:
		named(ckRecord),
		named(init)
)
public macro CloudKitRecord() = #externalMacro(module: "EmpireMacros", type: "CloudKitRecordMacro")
#endif
