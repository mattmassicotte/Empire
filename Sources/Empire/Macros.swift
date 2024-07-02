@_exported
import PackedSerialize

@attached(
	extension,
	conformances: IndexKeyRecord,
	names:
		named(IndexKey),
		named(indexKeySerializedSize),
		named(fieldsSerializedSize),
		named(indexKey),
		named(serialize),
		named(init),
		named(schemaVersion),
		named(select)
)
public macro IndexKeyRecord(
	_ first: StaticString,
	_ remaining: StaticString...
) = #externalMacro(module: "EmpireMacros", type: "IndexKeyRecordMacro")

@attached(
	extension,
	conformances: CloudKitRecord,
	names:
		named(ckRecord),
		named(init)
)
public macro CloudKitRecord() = #externalMacro(module: "EmpireMacros", type: "CloudKitRecordMacro")
