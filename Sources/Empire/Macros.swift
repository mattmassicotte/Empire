@_exported
import PackedSerialize

@attached(
	extension,
	conformances: IndexKeyRecord,
	names:
		named(indexKeySerializedSize),
		named(fieldsSerializedSize),
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
	names:
		named(doThing)
)
public macro CloudKitRecord() = #externalMacro(module: "EmpireMacros", type: "CloudKitRecordMacro")
