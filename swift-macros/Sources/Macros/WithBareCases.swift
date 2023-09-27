import MacrosImplementation

@attached(member, names: named(BareCase), named(bareCase))
public macro WithBareCases(
    access: WithBareCases.AccessLevelModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "WithBareCases")

@attached(member, names: arbitrary)
public macro WithBareCases(
    access: WithBareCases.AccessLevelModifier? = nil,
    typeName: String
) = #externalMacro(module: "MacrosImplementation", type: "WithBareCases")
