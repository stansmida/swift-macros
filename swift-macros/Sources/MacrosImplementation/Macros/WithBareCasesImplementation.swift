import SwiftDiagnostics
import SwiftExtras
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `WithBareCases` macro, which takes a declaration of
/// enum with associated value and produces nested enum type with same cases
/// without associated values.
///
/// For example
///
///     @WithBareCases
///     enum E {
///         case a(String)
///         case b(String, Int)
///     }
///
/// expands as
///
///     @WithBareCases
///     enum E {
///         case a(String)
///         case b(String, Int)
///
///         enum BareCase: Hashable {
///             case a
///             case b
///         }
///
///         var bareCase: BareCase {
///             switch self {
///                 case .a:
///                     .a
///                 case .b:
///                     .b
///             }
///         }
///     }
public enum WithBareCases: MemberMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {

        guard let enumDeclSyntax = declaration.as(EnumDeclSyntax.self) else {
            throw Diagnostic.invalidDeclarationGroupType(declaration, expected: [EnumDeclSyntax.self]).error(at: node)
        }

        let caseElements = enumDeclSyntax.memberBlock.members.compactMap { member in
            member.decl.as(EnumCaseDeclSyntax.self)?.elements.first!
        }
        guard caseElements.contains(where: { $0.parameterClause != nil }) else {
            throw Diagnostic.invalidDeclaration("'@\(Self.self)' can only be attached to an enum with associated values.").error(at: node)
        }

        let accessModifier = try Extract.typeAccessLevelModifier(explicit: node, implicit: enumDeclSyntax.modifiers).map({ "\($0.rawValue) " }) ?? ""

        let typeName = try Extract.attributeArgument(node, withLabel: "typeName") ?? "BareCase"

        // We make the expansion type `Hashable`. Obvious benefit "for free".
        let expansionEnumDeclSyntax = try EnumDeclSyntax("\(raw: accessModifier)enum \(raw: typeName): Hashable") {
            for caseElement in caseElements {
                try EnumCaseDeclSyntax("case \(caseElement.name)")
            }
        }
        // Check the type name is as expected.
        guard expansionEnumDeclSyntax.name.text == typeName else {
            throw Diagnostic.invalidArgument("Invalid type name: '\(typeName)'.").error(at: node)
        }

        let propertyName = typeName.lowercasedFirst
        let expansionPropertyDeclSyntax = try VariableDeclSyntax(
            "\(raw: accessModifier)var \(raw: propertyName): \(raw: typeName)",
            accessor: {
                try SwitchExprSyntax("switch self") {
                    for caseElement in caseElements {
                        SwitchCaseSyntax("case .\(caseElement.name): .\(caseElement.name)")
                    }
                }
            }
        )
        // Check the type name is as expected.
        let expansionPropertyName = expansionPropertyDeclSyntax.bindings.first?.as(PatternBindingSyntax.self)?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        guard expansionPropertyName == propertyName else {
            throw Diagnostic.invalidArgument("Invalid type name: '\(typeName)'.").error(at: node)
        }

        return [
            DeclSyntax(expansionEnumDeclSyntax),
            DeclSyntax(expansionPropertyDeclSyntax)
        ]
    }
}
