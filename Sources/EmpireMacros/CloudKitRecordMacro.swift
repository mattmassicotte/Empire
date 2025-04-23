import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CloudKitRecordMacro: ExtensionMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		let memberNames = declaration.propertyMemberNames

		let setters = memberNames
			.map {
				"record[\"\($0)\"] = \($0)"
			}
			.joined(separator: "\n")

		let initers = memberNames
			.map {
				"self.\($0) = try ckRecord.getTypedValue(for: \"\($0)\")"
			}
			.joined(separator: "\n")


		
		let inheritance = InheritanceClauseSyntax {
			InheritedTypeListSyntax {
				InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "CloudKitRecord"))
			}
		}
		
		let ext = ExtensionDeclSyntax(extendedType: type, inheritanceClause: inheritance) {
			DeclSyntax(
				"""
				public init(ckRecord: CKRecord) throws {
					try ckRecord.validateRecordType(Self.ckRecordType)
				
					\(raw: initers)
				}
				"""
			)

			DeclSyntax(
				"""
				public func ckRecord(with recordId: CKRecord.ID) -> CKRecord {
					let record = CKRecord(recordType: Self.ckRecordType, recordID: recordId)
				
					\(raw: setters)
				
					return record
				}
				"""
			)
		}
		
		return [
			ext
		]
	}
}
