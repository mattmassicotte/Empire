@attached(
	extension,
	conformances: IndexKeyRecord,
	names:
		named(PrimaryKey),
		named(Fields),
		named(primaryKey),
		named(fields),
		named(init),
		named(schemaHashValue),
		named(select)
)
public macro IndexKeyRecord(
	_ first: StaticString,
	_ remaining: StaticString...
) = #externalMacro(module: "EmpireMacros", type: "IndexKeyRecordMacro")
