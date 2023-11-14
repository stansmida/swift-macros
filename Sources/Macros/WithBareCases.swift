@_exported import enum SwiftSyntaxExtras.TypeAccessModifier

@attached(member, names: named(BareCase), named(bareCase), named(==))
public macro WithBareCases(
    accessModifier: TypeAccessModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "WithBareCases")

@attached(member, names: named(==(lhs:rhs:)), arbitrary)
public macro WithBareCases(
    accessModifier: TypeAccessModifier? = nil,
    typeName: String
) = #externalMacro(module: "MacrosImplementation", type: "WithBareCases")
