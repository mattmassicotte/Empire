import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum IndexKeyRecordMacroError: Error, CustomStringConvertible {
	case invalidType
	case invalidArguments
	case recordValidationFailure

	var description: String {
		switch self {
		case .invalidType:
			return "Record macro can only be attached to a struct"
		case .recordValidationFailure:
			return "Record fieldsVersion validation failed"
		case .invalidArguments:
			return "Record macro requires static string arguments"
		}
	}
}

public enum RecordVersion {
	case automatic
	case custom(key: Int, fields: Int)
	case customFields(Int)
	case customKey(Int)
	case validated(Int)
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
		let version = try recordValidation(node: node)
		let args = try RecordMacroArguments(type: type, declaration: declaration, keyMemberNames: keyMemberNames)

		return [
			try extensionDecl(argument: args, version: version),
			try dataManipulationExtensionDecl(argument: args),
		]
	}

	private static func decodeInteger(_ element: LabeledExprListSyntax.Element) -> Int? {
		let prefixOp = element
			.expression
			.as(PrefixOperatorExprSyntax.self)
		
		let negation = prefixOp?.operator.tokenKind == .prefixOperator("-")
		
		let intExp = prefixOp?.expression ?? element.expression
		
		let value = intExp
			.as(IntegerLiteralExprSyntax.self)
			.flatMap {
				Int($0.literal.text)
			}
		
		guard let value else {
			return nil
		}
		
		return negation ? value * -1 : value
	}
	
	private static func recordValidation(node: AttributeSyntax) throws -> RecordVersion {
		guard
			case let .argumentList(arguments) = node.arguments,
			arguments.isEmpty == false
		else {
			throw IndexKeyRecordMacroError.invalidArguments
		}

		var validatedValue: Int?
		var keyPrefixValue: Int?
		var fieldsVersionValue: Int?
		
		for argument in arguments {
			switch argument.label?.text {
			case "validated":
				validatedValue = decodeInteger(argument)
			case "keyPrefix":
				keyPrefixValue = decodeInteger(argument)
			case "fieldsVersion":
				fieldsVersionValue = decodeInteger(argument)
			default:
				break
			}
		}
		
		switch (validatedValue, keyPrefixValue, fieldsVersionValue) {
		case let (nil, b?, c?):
			return RecordVersion.custom(key: b, fields: c)
		case let (a?, nil, nil):
			return RecordVersion.validated(a)
		case let (nil, nil, c?):
			return RecordVersion.customFields(c)
		case let (nil, b?, nil):
			return RecordVersion.customKey(b)
		case (nil, nil, nil):
			return .automatic
		default:
			throw IndexKeyRecordMacroError.invalidArguments
		}
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
	private static func keyPrefixAccessor(
		argument: RecordMacroArguments<some TypeSyntaxProtocol, some DeclGroupSyntax>,
		version: RecordVersion
	) throws -> VariableDeclSyntax {
		let output = argument.type.trimmedDescription

		let schemaHash: Int
		
		switch version {
		case .automatic, .validated, .customFields:
			schemaHash = output.sdbmHashValue
		case let .custom(key: value, fields: _):
			schemaHash = value
		case let .customKey(value):
			schemaHash = value
		}

		let literal = IntegerLiteralExprSyntax(schemaHash)
		
		return try VariableDeclSyntax(
			"""
/// Input: "\(raw: output)"
public static var keyPrefix: Int { \(literal) }
"""
		)
	}

	/// Have to preserve types and order
	private static func fieldsVersionAccessor(
		argument: RecordMacroArguments<some TypeSyntaxProtocol, some DeclGroupSyntax>,
		version: RecordVersion
	) throws -> VariableDeclSyntax {
		let output = argument.fieldMemberTypeNames.joined(separator: ",")

		let schemaHash: Int
		
		switch version {
		case .automatic, .customKey:
			schemaHash = output.sdbmHashValue
		case let .custom(key: _, fields: value):
			schemaHash = value
		case let .customFields(value):
			schemaHash = value
		case let .validated(value):
			schemaHash = output.sdbmHashValue
			
			if value != schemaHash {
				throw IndexKeyRecordMacroError.recordValidationFailure
			}
		}

		let literal = IntegerLiteralExprSyntax(schemaHash)

		return try VariableDeclSyntax(
			"""
/// Input: "\(raw: output)"
public static var fieldsVersion: Int { \(literal) }
"""
		)
	}

	private static func extensionDecl(
		argument: RecordMacroArguments<some TypeSyntaxProtocol, some DeclGroupSyntax>,
		version: RecordVersion
	) throws -> ExtensionDeclSyntax {
		let keyTupleArguments = argument.keyMemberNames
			.joined(separator: ", ")
		let fieldsTupleArguments = argument.fieldMemberNames.isEmpty ? "EmptyValue()" : argument.fieldMemberNames
			.joined(separator: ", ")

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
		let fieldTypes = argument.fieldMemberTypeNames.isEmpty ? "EmptyValue" : argument.fieldMemberTypeNames.joined(separator: ", ")

		let fieldsInit = argument.fieldTypeNamePairs
			.map { "self.\($0) = try \($1)(buffer: &buffer.valueBuffer)" }
			.joined(separator: "\n")

		let fullInit = [keyInit, fieldsInit].joined(separator: "")
		let fullSerialize = [keySerialize, fieldsSerialize].joined(separator: "")
		
		let serializeFunction = try FunctionDeclSyntax(
"""
public func serialize(into buffer: inout SerializationBuffer) {
	\(raw: fullSerialize)
}
"""
		)

		return try ExtensionDeclSyntax(
	"""
extension \(argument.type.trimmed): IndexKeyRecord {
	public typealias IndexKey = Tuple<\(raw: keyTypes)>
	public typealias Fields = Tuple<\(raw: fieldTypes)>

	\(try keyPrefixAccessor(argument: argument, version: version))

	\(try fieldsVersionAccessor(argument: argument, version: version))

	public var indexKey: IndexKey { Tuple(\(raw: keyTupleArguments)) }

	public var fields: Fields { Tuple(\(raw: fieldsTupleArguments)) }

	\(serializeFunction)

	public init(_ buffer: inout DeserializationBuffer) throws {
		\(raw: fullInit)
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
