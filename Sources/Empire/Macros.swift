@attached(
	extension,
	conformances: IndexKeyRecord,
	names:
		named(indexKeySerializedSize),
		named(fieldsSerializedSize),
		named(serialize),
		named(init),
		named(schemaHashValue),
		named(select)
)
public macro IndexKeyRecord(
	_ first: StaticString,
	_ remaining: StaticString...
) = #externalMacro(module: "EmpireMacros", type: "IndexKeyRecordMacro")
