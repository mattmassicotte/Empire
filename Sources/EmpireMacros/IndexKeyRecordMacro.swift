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
			try extensionDecl(argument: args),
			try dataManipulationExtensionDecl(argument: args),
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
	private static func schemaHashcodeAccessor(members: [PatternBindingSyntax]) throws -> VariableDeclSyntax {
		let output = members.map { $0.description }.joined(separator: ",")

		let schemaHash = output.checksum
		let literal = IntegerLiteralExprSyntax(schemaHash)

		return try VariableDeclSyntax(
			"""
public static var schemaVersion: Int { \(literal) }
"""
		)
	}

	private static func extensionDecl(
		argument: RecordMacroArguments<some TypeSyntaxProtocol, some DeclGroupSyntax>
	) throws -> ExtensionDeclSyntax {
		let keySize = argument.keyMemberNames
			.map { "\($0).serializedSize" }
			.joined(separator: " +\n")

		let keyTupleArguments = argument.keyMemberNames
			.joined(separator: ", ")

		// handle no fields
		let fieldSize: String

		if argument.fieldMemberNames.isEmpty {
			fieldSize = "0"
		} else {
			fieldSize = argument.fieldMemberNames
				.map { "\($0).serializedSize" }
				.joined(separator: " +\n")
		}

		let keySerialize = argument.keyMemberNames
			.map { "\($0).serialize(into: &buffer.keyBuffer)" }
			.joined(separator: "\n")

		let fieldsSerialize = argument.fieldMemberNames
			.map { "\($0).serialize(into: &buffer.valueBuffer)" }
			.joined(separator: "\n")

		let keyInit = argument.primaryKeyTypeNamePairs
			.map { "self.\($0) = try \($1)(buffer: &buffer.keyBuffer)" }
			.joined(separator: "\n")

		let keyTypes = argument.primaryKeyTypeNamePairs
			.map { $1 }
			.joined(separator: ", ")

		let fieldsInit = argument.fieldTypeNamePairs
			.map { "self.\($0) = try \($1)(buffer: &buffer.valueBuffer)" }
			.joined(separator: "\n")

		let serializeFunction = try FunctionDeclSyntax(
			"""
public func serialize(into buffer: inout SerializationBuffer) {
	\(raw: keySerialize)
	\(raw: fieldsSerialize)
}
"""
		)

		let indexKeySerializedSizeVar = try VariableDeclSyntax(
"""
public var indexKeySerializedSize: Int {
	\(raw: keySize)
}
"""
		)

		let fieldsSerializedSizeVar = try VariableDeclSyntax(
"""
public var fieldsSerializedSize: Int {
	\(raw: fieldSize)
}
"""
		)

		return try ExtensionDeclSyntax(
	"""
extension \(argument.type.trimmed): IndexKeyRecord {
	public typealias IndexKey = Tuple<\(raw: keyTypes)>

	\(try schemaHashcodeAccessor(members: argument.members))

	\(indexKeySerializedSizeVar)

	\(fieldsSerializedSizeVar)

	public var indexKey: IndexKey {
		Tuple(\(raw: keyTupleArguments))
	}

	\(serializeFunction)

	public init(_ buffer: inout DeserializationBuffer) throws {
		\(raw: keyInit)
		\(raw: fieldsInit)
	}
}
"""
		)
	}

	private static func dataManipulationExtensionDecl(
		argument: RecordMacroArguments<some TypeSyntaxProtocol, some DeclGroupSyntax>
	) throws -> ExtensionDeclSyntax {
		let pairs = argument.primaryKeyTypeNamePairs

		var selectFunctions = [FunctionDeclSyntax]()

		for (pair, index) in zip(pairs, pairs.indices) {
			let prefix = pairs.prefix(index)
			let prefixParams = prefix.map({ "\($0.0): \($0.1)" })

			let comparisonParams = prefixParams + ["\(pair.0): ComparisonOperator<\(pair.1)>"]
			let comparisonParamString = comparisonParams.joined(separator: ", ")

			let comparisonArgs = prefix.map({ $0.0 }) + ["last: \(pair.0)"]
			let comparisonArgString = comparisonArgs.joined(separator: ", ")

			let comparisonFuncDecl = try FunctionDeclSyntax(
"""
public static func select(in context: TransactionContext, limit: Int? = nil, \(raw: comparisonParamString)) throws -> [Self] {
	try context.select(query: Query(\(raw: comparisonArgString), limit: limit))
}
"""
			)

			selectFunctions.append(comparisonFuncDecl)

			let equalityParams = prefixParams + ["\(pair.0): \(pair.1)"]
			let equalityParamString = equalityParams.joined(separator: ", ")

			let equalityArgs = prefix.map({ $0.0 }) + ["last: .equals(\(pair.0))"]
			let equalityArgString = equalityArgs.joined(separator: ", ")

			let equalityFuncDecl = try FunctionDeclSyntax(
"""
public static func select(in context: TransactionContext, limit: Int? = nil, \(raw: equalityParamString)) throws -> [Self] {
	try context.select(query: Query(\(raw: equalityArgString), limit: limit))
}
"""
			)

			selectFunctions.append(equalityFuncDecl)

		}

		return ExtensionDeclSyntax(
			extendedType: argument.type,
			memberBlock: MemberBlockSyntax(
				members: MemberBlockItemListSyntax(
					selectFunctions.map { MemberBlockItemSyntax(decl: $0) }
				)
			)
		)
	}
}
