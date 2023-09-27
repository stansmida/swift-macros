import SwiftDiagnostics
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
public struct WithBareCases: MemberMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {

        guard let enumDeclSyntax = declaration.as(EnumDeclSyntax.self) else {
            throw diagnosticsError(.notAnEnum(declaration), at: node)
        }

        let caseElements = enumDeclSyntax.memberBlock.members.compactMap { member in
            member.decl.as(EnumCaseDeclSyntax.self)?.elements.first!
        }
        guard caseElements.contains(where: { $0.parameterClause != nil }) else {
            throw diagnosticsError(.noAssociatedValue, at: node)
        }

        // First we look for explicit access level modifier parameter on the macro, if there is none
        // we extract access level modifier of the enum that the macro is attached to, which can be also
        // omitted - resulting in nil.
        let accessLevelModifier = try extractAccessLevelModifier(from: node) ?? extractAccessLevelModifier(from: enumDeclSyntax)
        let declAccess = accessLevelModifier.map({ "\($0.rawValue) " }) ?? ""

        let typeName = try extractTypeName(node: node) ?? "BareCase"

        // We make the expansion type `Hashable`. Obviously benefits "for free".
        let expansionEnumDeclSyntax = try EnumDeclSyntax("\(raw: declAccess)enum \(raw: typeName): Hashable") {
            for caseElement in caseElements {
                try EnumCaseDeclSyntax("case \(caseElement.name)")
            }
        }
        // Check the type name is as expected.
        guard expansionEnumDeclSyntax.name.text == typeName else {
            throw diagnosticsError(.corruptedTypeName(typeName, corruptedDeclName: expansionEnumDeclSyntax.name.text), at: node)
        }

        let propertyName = typeName.lowercasedFirst
        let expansionPropertyDeclSyntax = try VariableDeclSyntax(
            "\(raw: declAccess)var \(raw: propertyName): \(raw: typeName)",
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
            throw diagnosticsError(.corruptedTypeName(typeName, corruptedDeclName: expansionPropertyName), at: node)
        }

        return [
            DeclSyntax(expansionEnumDeclSyntax),
            DeclSyntax(expansionPropertyDeclSyntax)
        ]
    }

    private static func extractAccessLevelModifier(from node: AttributeSyntax) throws -> AccessLevelModifier? {
        guard
            let labeledExprSyntax = node.arguments?.as(LabeledExprListSyntax.self)?.first(where: { $0.label?.text == "access" })
        else {
            // Omitted access parameter is allowed.
            return nil
        }
        guard
            !labeledExprSyntax.expression.is(NilLiteralExprSyntax.self)
        else {
            // Access parameter is of optional type and can be explicitly nil (literal) - same behavior as omitted.
            return nil
        }
        guard
            let text = labeledExprSyntax.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        else {
            throw diagnosticsError(.internal(message: "Unexpected `access` expression: '\(labeledExprSyntax.expression)'."), at: node)
        }
        guard let accessLevelModifier = AccessLevelModifier(rawValue: text) else {
            throw diagnosticsError(.internal(message: "Unexpected access level modifier: '\(text)'."), at: node)
        }
        return accessLevelModifier
    }

    private static func extractAccessLevelModifier(from enumDeclSyntax: EnumDeclSyntax) -> AccessLevelModifier? {
        enumDeclSyntax.modifiers.lazy.compactMap({ AccessLevelModifier($0) }).first
    }

    private static func extractTypeName(node: AttributeSyntax) throws -> String? {
        guard
            let labeledExprSyntax = node.arguments?.as(LabeledExprListSyntax.self)?.first(where: { $0.label?.text == "typeName" })
        else {
            return nil
        }
        guard
            let stringLiteralExprSyntax = labeledExprSyntax.expression.as(StringLiteralExprSyntax.self),
            stringLiteralExprSyntax.segments.count == 1,
            let typeName = stringLiteralExprSyntax.segments.firstToken(viewMode: .sourceAccurate)?.text,
            !typeName.isEmpty
        else {
            throw diagnosticsError(.corruptedTypeName("\(labeledExprSyntax)", corruptedDeclName: nil), at: node)
        }
        return typeName
    }

    private static func diagnosticsError(_ error: WithBareCasesDiagnostic, at node: AttributeSyntax) -> DiagnosticsError {
        .init(diagnostics: [.init(node: node, message: error)])
    }
}

public extension WithBareCases {

    enum AccessLevelModifier: String {

        /// This modifier doesn't have `open` case since it is always `Enum` declaration modifier.
        case `public`, `internal`, `fileprivate`, `private`

        fileprivate static var `default`: Self { .internal }

        fileprivate init?(_ declModifierSyntax: DeclModifierSyntax) {
            switch declModifierSyntax.name.tokenKind {
                case .keyword(.public): self = .public
                case .keyword(.internal): self = .internal
                case .keyword(.fileprivate): self = .fileprivate
                case .keyword(.private): self = .private
                default: return nil
            }
        }

        fileprivate var keyword: Keyword {
            switch self {
                case .public: .public
                case .internal: .internal
                case .fileprivate: .fileprivate
                case .private: .private
            }
        }
    }
}

private extension WithBareCases {

    enum WithBareCasesDiagnostic: DiagnosticMessage {

        /// `typeName` parameter is of `String`. Any issue to build the expansion type and property with the
        /// argument results in emitting this error.
        case corruptedTypeName(String, corruptedDeclName: String?)
        /// Error in this macro implementation, typically caused by unexpected syntax.
        case `internal`(message: String)
        /// Enum with cases that don't have associated values does't need this macro.
        case noAssociatedValue
        /// You can obviously attach this macro only to an enum. Attaching to any other kind
        /// emits this error.
        case notAnEnum(DeclGroupSyntax)

        var diagnosticID: MessageID {
            switch self {
                case .corruptedTypeName:
                    MessageID(domain: "\(Self.self)", id: "corruptedTypeName")
                case .internal:
                    MessageID(domain: "\(Self.self)", id: "internal")
                case .noAssociatedValue:
                    MessageID(domain: "\(Self.self)", id: "noAssociatedValue")
                case .notAnEnum:
                    MessageID(domain: "\(Self.self)", id: "notAnEnum")
            }
        }

        var message: String {
            switch self {
                case .corruptedTypeName(let value, let corruptedDeclName):
                    "Corrupted `typeName` argument: '\(value)'; resluting in \(corruptedDeclName.map({ "'\($0)'" }) ?? "`nil`")."
                case .internal(let message):
                    "Internal error: \(message)"
                case .noAssociatedValue:
                    "'@WithBareCases' can only be attached to an enum with associated values."
                case .notAnEnum(let decl):
                    "'@WithBareCases' can only be attached to an enum, not \(decl.kind)."
            }
        }

        var severity: DiagnosticSeverity {
            switch self {
                case .corruptedTypeName: .error
                case .internal: .error
                case .noAssociatedValue: .error
                case .notAnEnum: .error
            }
        }
    }
}

private extension String {
    var lowercasedFirst: String {
        guard let first else {
            return self
        }
        return "\(first.lowercased())\(dropFirst())"
    }
}
