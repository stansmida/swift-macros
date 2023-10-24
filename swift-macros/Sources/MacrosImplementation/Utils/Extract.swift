import SwiftSyntax

enum Extract {

    static func attributeArgument(
        _ node: AttributeSyntax,
        withLabel label: String
    ) throws -> String? {
        guard let arguments = node.arguments else {
            // Ommitted arguments is allowed. This is same as omitted or nil labeled argument below.
            return nil
        }
        guard let labeledExprSyntax = arguments.as(LabeledExprListSyntax.self) else {
            throw Diagnostic.internal(debugMessage: "Unexpected arguments type.").error(at: node)
        }
        guard let labeledExprSyntax = labeledExprSyntax.first(where: { $0.label?.text == label }) else {
            // Omitted argument for given label is allowed.
            return nil
        }
        guard !labeledExprSyntax.expression.is(NilLiteralExprSyntax.self) else {
            // Optioanl parameter is allowed and can be explicitly or default
            // `nil` (literal) - same behavior as omitted.
            return nil
        }
        if let stringLiteralExprSyntax = labeledExprSyntax.expression.as(StringLiteralExprSyntax.self) {
            guard let text = stringLiteralExprSyntax.segments.firstToken(viewMode: .sourceAccurate)?.text else {
                throw Diagnostic.internal(debugMessage: "Unexpected '\(label)' expression: '\(stringLiteralExprSyntax)'.").error(at: node)
            }
            return text
        } else if let memberAccessExprSyntax = labeledExprSyntax.expression.as(MemberAccessExprSyntax.self) { // For parameter types that accept members, e.g. an enum case.
            let text = memberAccessExprSyntax.declName.baseName.text
            return text
        } else {
            throw Diagnostic.internal(debugMessage: "Unexpected '\(label)' expression type: \(labeledExprSyntax.expression).").error(at: node)
        }
    }

    static func protocolName(_ syntax: ProtocolDeclSyntax, of node: SwiftSyntax.AttributeSyntax) throws -> String {
        guard case .identifier(let name) = syntax.name.tokenKind else {
            throw Diagnostic.internal(debugMessage: "Unexpected token kind: '\(syntax.name.tokenKind)'.").error(at: node)
        }
        return name
    }

    static func typeAccessLevelModifier(
        explicit node: AttributeSyntax,
        implicit declSyntax: DeclModifierListSyntax
    ) throws -> TypeAccessModifier? {
        let explicit = try explicitTypeAccessModifier(from: node)
        let implicit = implicitTypeAccessModifier(from: declSyntax)
        if let explicit {
            guard explicit <= (implicit ?? .internal) else {
                throw Diagnostic.invalidArgument("Expansion type cannot have less restrictive access than its anchor declaration.").error(at: node)
            }
        }
        return explicit ?? implicit
    }

    private static func explicitTypeAccessModifier(from node: AttributeSyntax) throws -> TypeAccessModifier? {
        guard let text = try attributeArgument(node, withLabel: TypeAccessModifier.parameterLabel) else {
            return nil
        }
        guard let accessModifier = TypeAccessModifier(rawValue: text) else {
            throw Diagnostic.internal(debugMessage: "Unexpected access modifier: '\(text)'.").error(at: node)
        }
        return accessModifier
    }

    private static func implicitTypeAccessModifier(from declSyntax: DeclModifierListSyntax) -> TypeAccessModifier? {
        declSyntax.lazy.compactMap({ TypeAccessModifier($0) }).first
    }
}
