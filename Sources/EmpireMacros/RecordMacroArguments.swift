import SwiftCompilerPlugin
import SwiftSyntax

extension DeclGroupSyntax {
	var propertyMembers: [PatternBindingSyntax] {
		memberBlock.members
			.compactMap {
				$0.decl.as(VariableDeclSyntax.self)
			}
			.compactMap {
				$0.bindings.first
			}
	}

	var propertyMemberNames: [String] {
		propertyMembers.compactMap {
			$0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
		}
	}
}

struct RecordMacroArguments<Type: TypeSyntaxProtocol, Declaration: DeclGroupSyntax> {
	let type: Type
	let declaration: Declaration
	let members: [PatternBindingSyntax]
	let keyMemberNames: [String]

	init(type: Type, declaration: Declaration, keyMemberNames: [String]) throws {
		self.type = type
		self.declaration = declaration
		self.keyMemberNames = keyMemberNames

		self.members = try Self.members(of: declaration)
	}

	private var memberNames: [String] {
		members.compactMap {
			$0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
		}
	}

	var primaryKeyTypeNamePairs: [(String, String)] {
		members.compactMap { member in
			guard let name = member.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
				return nil
			}

			if keyMemberNames.contains(name) == false {
				return nil
			}

			guard let typeName = member.typeAnnotation?.type.description else {
				return nil
			}

			return (name, typeName)
		}
	}

	var fieldTypeNamePairs: [(String, String)] {
		members.compactMap { member in
			guard let name = member.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
				return nil
			}

			if keyMemberNames.contains(name) {
				return nil
			}

			guard let typeName = member.typeAnnotation?.type.description else {
				return nil
			}

			return (name, typeName)
		}
	}

	var primaryKeyMembers: [PatternBindingSyntax] {
		members.filter { member in
			guard let name = member.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
				return false
			}

			return keyMemberNames.contains(name)
		}
	}

	var fieldMembers: [PatternBindingSyntax] {
		members.filter { member in
			guard let name = member.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
				return false
			}

			return keyMemberNames.contains(name) == false
		}
	}

	var keyMemberTypeNames: [String] {
		primaryKeyMembers.compactMap { $0.typeAnnotation?.type.description }
	}

	var fieldMemberTypeNames: [String] {
		fieldMembers.compactMap { $0.typeAnnotation?.type.description }
	}

	var fieldMemberNames: [String] {
		memberNames.filter { name in
			return keyMemberNames.contains(name) == false
		}
	}

	private static func members(of declaration: some DeclGroupSyntax) throws -> [PatternBindingSyntax] {
		guard
			let decl = declaration.as(StructDeclSyntax.self)
		else {
			throw IndexKeyRecordMacroError.invalidType
		}

		return decl.memberBlock.members
			.compactMap {
				$0.decl.as(VariableDeclSyntax.self)
			}
			.compactMap {
				$0.bindings.first
			}
	}
}
