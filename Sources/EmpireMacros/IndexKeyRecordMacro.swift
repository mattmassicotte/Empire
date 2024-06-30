import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum IndexKeyRecordMacroError: Error, CustomStringConvertible {
	case invalidType
	case invalidArguments

	var description: String {
		switch self {
		case .invalidType:
			return "Record macro can only be attached to a struct"
		case .invalidArguments:
			return "Record macro requires static string arguments"
		}
	}
}

public struct IndexKeyRecordMacro: ExtensionMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		let keyMemberNames = try keyMemberNames(node: node)
		let args = try RecordMacroArguments(type: type, declaration: declaration, keyMemberNames: keyMemberNames)

		return [
			try extensionDecl(argument: args)
		]
	}

	private static func keyMemberNames(node: AttributeSyntax) throws -> [String] {
		guard
			case let .argumentList(arguments) = node.arguments,
			arguments.isEmpty == false
		else {
			throw IndexKeyRecordMacroError.invalidArguments
		}

		return arguments
			.compactMap { $0.expression.as(StringLiteralExprSyntax.self) }
			.compactMap {
				switch $0.segments.first {
				case let .stringSegment(segment):
					return segment
				default:
					return nil
				}
			}
			.map { $0.content.text }
	}
}

extension IndexKeyRecordMacro {
	/// Have to preserve types and order
	private static func schemaHashcodeAccessor(members: [PatternBindingSyntax]) -> DeclSyntax {
		let output = members.map { $0.description }.joined(separator: ",")

		let schemaHash = output.checksum

		return """
static var schemaHashValue: Int { \(raw: schemaHash) }
"""
	}

	private static func extensionDecl(
		argument: RecordMacroArguments<some TypeSyntaxProtocol, some DeclGroupSyntax>
	) throws -> ExtensionDeclSyntax {
		let keySize = argument.keyMemberNames
			.map { "\($0).serializedSize" }
			.joined(separator: " +\n")

		let fieldSize = argument.fieldMemberNames
			.map { "\($0).serializedSize" }
			.joined(separator: " +\n")

		let keySerialize = argument.keyMemberNames
			.map { "\($0).serialize(into: &buffer.keyBuffer)" }
			.joined(separator: "\n")

		let fieldsSerialize = argument.fieldMemberNames
			.map { "\($0).serialize(into: &buffer.valueBuffer)" }
			.joined(separator: "\n")

		let keyInit = argument.primaryKeyTypeNamePairs
			.map { "self.\($0) = try \($1)(buffer: &buffer.keyBuffer)" }
			.joined(separator: "\n")

		let fieldsInit = argument.fieldTypeNamePairs
			.map { "self.\($0) = try \($1)(buffer: &buffer.valueBuffer)" }
			.joined(separator: "\n")

		return try ExtensionDeclSyntax(
			"""
extension \(argument.type.trimmed): IndexKeyRecord {
	\(raw: schemaHashcodeAccessor(members: argument.members))

	public var indexKeySerializedSize: Int {
		\(raw: keySize)
	}

	public var fieldsSerializedSize: Int {
		\(raw: fieldSize)
	}

	public func serialize(into buffer: inout SerializationBuffer) {
		\(raw: keySerialize)
		\(raw: fieldsSerialize)
	}

	public init(_ buffer: inout DeserializationBuffer) throws {
		\(raw: keyInit)
		\(raw: fieldsInit)
	}
}
"""
		)
	}

}
