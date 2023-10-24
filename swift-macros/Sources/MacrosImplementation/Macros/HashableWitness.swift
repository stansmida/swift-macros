import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum HashableExistential: PeerMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        try HashableExistentialExpansion.expansion(of: node, providingPeersOf: declaration, in: context, bindingSpecifier: .let, optional: false)
    }
}

public enum HashableOptionalExistential: PeerMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        try HashableExistentialExpansion.expansion(of: node, providingPeersOf: declaration, in: context, bindingSpecifier: .let, optional: true)
    }
}

public enum HashableMutableExistential: PeerMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        try HashableExistentialExpansion.expansion(of: node, providingPeersOf: declaration, in: context, bindingSpecifier: .var, optional: false)
    }
}

public enum HashableMutableOptionalExistential: PeerMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        try HashableExistentialExpansion.expansion(of: node, providingPeersOf: declaration, in: context, bindingSpecifier: .var, optional: true)
    }
}

public enum HashableSequenceOfExistential: PeerMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        try HashableSequenceOfExistentialExpansion.expansion(of: node, providingPeersOf: declaration, in: context, bindingSpecifier: .let)
    }
}

public enum HashableMutableSequenceOfExistential: PeerMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        try HashableSequenceOfExistentialExpansion.expansion(of: node, providingPeersOf: declaration, in: context, bindingSpecifier: .var)
    }
}

private enum HashableExistentialExpansion {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
        bindingSpecifier: BindingSpecifier,
        optional: Bool
    ) throws -> [SwiftSyntax.DeclSyntax] {
        do {
            guard let protocolDeclSyntax = declaration.as(ProtocolDeclSyntax.self) else {
                throw Diagnostic.invalidDeclarationType(declaration, expected: [ProtocolDeclSyntax.self]).error(at: node)
            }
            let accessModifier = try Extract.typeAccessLevelModifier(explicit: node, implicit: protocolDeclSyntax.modifiers)
            let protocolName = try Extract.protocolName(protocolDeclSyntax, of: node)
            let declSyntax = hashableDeclSyntax(accessModifier: accessModifier, protocolName: protocolName, bindingSpecifier: bindingSpecifier, optional: optional)
            return [declSyntax]
        } catch {
            throw error.diagnosticError(at: node)
        }
    }

    private static func hashableDeclSyntax(accessModifier: TypeAccessModifier?, protocolName: String, bindingSpecifier: BindingSpecifier, optional: Bool) -> DeclSyntax {
        let typeAccessModifier = accessModifier.map({ "\($0.rawValue) " }) ?? ""
        let requiredAccessModifier = accessModifier == .public ? "\(TypeAccessModifier.public.rawValue) " : ""
        let wrappedValueType = optional ? "(any \(protocolName))?" : "any \(protocolName)"
        let requiredInit = switch accessModifier {
        case .open:
            fatalError("Will not get here since protocol cannot be open.")
        case .public:
            "public init(wrappedValue: \(wrappedValueType)) {\nself.wrappedValue = wrappedValue\n}"
        case .private:
            "fileprivate init(wrappedValue: \(wrappedValueType)) {\nself.wrappedValue = wrappedValue\n}"
        case .internal, .fileprivate, nil:
            ""
        }
        let equatableImpl = optional
        ? "if let lhs = lhs.wrappedValue, let rhs = rhs.wrappedValue {\nlhs.isEqual(to: rhs)\n} else {\nlhs.wrappedValue == nil && rhs.wrappedValue == nil\n}"
        : "lhs.wrappedValue.isEqual(to: rhs.wrappedValue)"
        let hashImpl = optional
        ? "if let wrappedValue {\nhasher.combine(ObjectIdentifier(type(of: wrappedValue)))\nhasher.combine(wrappedValue)\n} else {\nhasher.combine(ObjectIdentifier(type(of: wrappedValue)))\n}"
        : "hasher.combine(ObjectIdentifier(type(of: wrappedValue)))\nhasher.combine(wrappedValue)"
        let expansionTypeNamePrefix = switch (bindingSpecifier, optional) {
            case (.let, let optional): optional ? "HashableOptional" : "Hashable"
            case (.var, let optional): optional ? "HashableMutableOptional" : "HashableMutable"
        }
        let declSyntax = DeclSyntax(
            """
            @propertyWrapper
            \(raw: typeAccessModifier)struct \(raw: expansionTypeNamePrefix)\(raw: protocolName): Hashable {
                \(raw: requiredInit)
                \(raw: requiredAccessModifier)\(raw: bindingSpecifier.rawValue) wrappedValue: \(raw: wrappedValueType)
                \(raw: requiredAccessModifier)var projectedValue: Self { self }
                \(raw: requiredAccessModifier)static func ==(lhs: Self, rhs: Self) -> Bool {
                    \(raw: equatableImpl)
                }
                \(raw: requiredAccessModifier)func hash(into hasher: inout Hasher) {
                    \(raw: hashImpl)
                }
            }
            """
        )
        return declSyntax
    }
}

private enum HashableSequenceOfExistentialExpansion {

    static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
        bindingSpecifier: BindingSpecifier
    ) throws -> [SwiftSyntax.DeclSyntax] {
        do {
            guard let protocolDeclSyntax = declaration.as(ProtocolDeclSyntax.self) else {
                throw Diagnostic.invalidDeclarationType(declaration, expected: [ProtocolDeclSyntax.self]).error(at: node)
            }
            let accessModifier = try Extract.typeAccessLevelModifier(explicit: node, implicit: protocolDeclSyntax.modifiers)
            let protocolName = try Extract.protocolName(protocolDeclSyntax, of: node)
            let declSyntax = hashableSequenceDeclSyntax(accessModifier: accessModifier, protocolName: protocolName, bindingSpecifier: bindingSpecifier)
            return [declSyntax]
        } catch {
            throw error.diagnosticError(at: node)
        }
    }

    private static func hashableSequenceDeclSyntax(accessModifier: TypeAccessModifier?, protocolName: String, bindingSpecifier: BindingSpecifier) -> DeclSyntax {
        let typeAccessModifier = accessModifier.map({ "\($0.rawValue) " }) ?? ""
        let requiredAccessModifier = accessModifier == .public ? "\(TypeAccessModifier.public.rawValue) " : ""
        let requiredInit = switch accessModifier {
        case .open:
            fatalError("Will not get here since protocol cannot be open.")
        case .public:
            "public init(wrappedValue: T) {\nself.wrappedValue = wrappedValue\n}"
        case .private:
            "fileprivate init(wrappedValue: T) {\nself.wrappedValue = wrappedValue\n}"
        case .internal, .fileprivate, nil:
            ""
        }
        let expansionTypeNamePrefix = switch bindingSpecifier {
            case .let: "HashableSequenceOf"
            case .var: "HashableMutableSequenceOf"
        }
        let declSyntax = DeclSyntax(
            """
            @propertyWrapper
            \(raw: typeAccessModifier)struct \(raw: expansionTypeNamePrefix)\(raw: protocolName)<T>: Hashable where T: Sequence, T.Element == any \(raw: protocolName) {
                \(raw: requiredInit)
                \(raw: requiredAccessModifier)\(raw: bindingSpecifier.rawValue) wrappedValue: T
                \(raw: requiredAccessModifier)var projectedValue: Self { self }
                \(raw: requiredAccessModifier)static func ==(lhs: Self, rhs: Self) -> Bool {
                    zip(lhs.wrappedValue, rhs.wrappedValue).allSatisfy {
                        // Ideally `$0.0.isEqual(to: $0.1)` but ATM there seems to be a bug preventing to compile this.
                        (); return $0.0.isEqual(to: $0.1)
                    }
                }
                \(raw: requiredAccessModifier)func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(T.self))
                    for element in wrappedValue {
                        hasher.combine(element)
                    }
                }
            }
            """
        )
        return declSyntax
    }
}
