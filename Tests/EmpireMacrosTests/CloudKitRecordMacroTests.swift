import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacroExpansion
import Testing

#if canImport(EmpireMacros) && canImport(CloudKit)
import EmpireMacros

let specs: [String: MacroSpec] = [
	"CloudKitRecord": MacroSpec(type: CloudKitRecordMacro.self)
]

struct CloudKitRecordMacroTests {
	@Test func testMacro() throws {
		assertMacroExpansion(
"""
@CloudKitRecord
struct CloudKitTestRecord: Hashable {
	let a: String
	let b: Int
	var c: String
}
""",
			expandedSource:
"""
struct CloudKitTestRecord: Hashable {
	let a: String
	let b: Int
	var c: String
}

extension CloudKitTestRecord : CloudKitRecord {
	public init(ckRecord: CKRecord) throws {
		try ckRecord.validateRecordType(Self.ckRecordType)

		self.a = try ckRecord.getTypedValue(for: "a")
		self.b = try ckRecord.getTypedValue(for: "b")
		self.c = try ckRecord.getTypedValue(for: "c")
	}

	public func ckRecord(with recordId: CKRecord.ID) -> CKRecord {
		let record = CKRecord(recordType: Self.ckRecordType, recordID: recordId)

		record["a"] = a
		record["b"] = b
		record["c"] = c

		return record
	}
}
""",
			macroSpecs: specs,
			failureHandler: { Issue.record($0) }
		)
	}
}
#endif
