import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(EmpireMacroMacros)
import EmpireMacros
import MacroInterface

let testMacros: [String: Macro.Type] = [
    "IndexKeyRecord": IndexKeyRecordMacro.self,
]

struct EmpireMacrosTests {
	@Test func testMacro() throws {
//		assertMacroExpansion(
//			"""
//			#stringify(a + b)
//			""",
//			expandedSource: """
//			(a + b, "a + b")
//			""",
//			macros: testMacros
//		)
	}
}
#endif
