import MacrosImplementation

@attached(member, names: named(BareCase), named(bareCase))
public macro WithBareCases(
    accessModifier: TypeAccessModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "WithBareCases")

@attached(member, names: arbitrary)
public macro WithBareCases(
    accessModifier: TypeAccessModifier? = nil,
    typeName: String
) = #externalMacro(module: "MacrosImplementation", type: "WithBareCases")
