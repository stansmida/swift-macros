import SwiftDiagnostics
import SwiftExtras
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxExtras
import SwiftSyntaxMacros

/// Implementation of the `BareProviding` macro, which takes a declaration of
/// enum with associated value and produces nested enum type with same cases
/// without associated values.
///
/// For example
///
///     @BareProviding
///     enum E {
///         case a(String)
///         case b(String, Int)
///     }
///
/// expands as
///
///     enum E {
///         case a(String)
///         case b(String, Int)
///
///         enum Bare: Hashable {
///             case a
///             case b
///         }
///
///         var bare: Bare {
///             switch self {
///                 case .a:
///                     .a
///                 case .b:
///                     .b
///             }
///         }
///     }
public enum BareProviding: MemberMacro {

    private static let accessModifierLabel = "accessModifier"

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {

        do {

            let anchorDecl = try DeclSyntaxScanner(declSyntax: declaration)
            let attribute = AttributeSyntaxScanner(node: node)

            guard case .enum(let enumDecl) = anchorDecl.type else {
                throw Diagnostic.invalidDeclarationGroupType(
                    declaration,
                    expected: [EnumDeclSyntax.self]
                )
                .error(at: node)
            }
            let caseElements: [EnumCaseElementSyntax] = enumDecl.memberBlock.members.flatMap { member in
                member.decl.as(EnumCaseDeclSyntax.self)?.elements.map { $0 } ?? []
            }
            guard caseElements.contains(where: { $0.parameterClause != nil }) else {
                throw Diagnostic.invalidDeclaration("'@\(Self.self)' can only be attached to an enum with associated values.").error(at: node)
            }

            let accessModifier = try TypeAccessModifier(withLabel: accessModifierLabel, in: declaration, at: node)
            let memberAccessModifierWithSpaceAfter = accessModifier.map { String(describing: $0.memberDerivate) + " " } ?? ""

            let typeName = try attribute.stringLiteralArgument(with: "typeName") ?? "Bare"

            let expansionEnumDecl = try EnumDeclSyntax(
                "\(raw: memberAccessModifierWithSpaceAfter)enum \(raw: typeName): Hashable"
            ) {
                for caseElement in caseElements {
                    try EnumCaseDeclSyntax("case \(caseElement.name)")
                }
            }

            // Check the type name is as expected.
            guard expansionEnumDecl.name.text == typeName else {
                throw Diagnostic.invalidArgument("Invalid type name: '\(typeName)'.").error(at: node)
            }

            let propertyName = typeName.lowercasedFirst
            let expansionPropertyDeclSyntax = try VariableDeclSyntax(
                "\(raw: memberAccessModifierWithSpaceAfter)var \(raw: propertyName): \(raw: typeName)",
                accessor: {
                    try SwitchExprSyntax("switch self") {
                        for caseElement in caseElements {
                            SwitchCaseSyntax("case .\(caseElement.name): .\(caseElement.name)")
                        }
                    }
                }
            )

            // Check the property name is as expected.
            let expansionPropertyName = expansionPropertyDeclSyntax.bindings.first?.as(PatternBindingSyntax.self)?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            guard expansionPropertyName == propertyName else {
                throw Diagnostic.invalidArgument("Invalid type name: '\(typeName)'.").error(at: node)
            }

            return [
                DeclSyntax(expansionEnumDecl),
                DeclSyntax(expansionPropertyDeclSyntax),
            ]
        } catch {
            throw error.diagnosticError(at: node)
        }
    }
}
