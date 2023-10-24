@_exported import SwiftExtras
import MacrosImplementation

@attached(peer, names: prefixed(Hashable))
public macro HashableExistential(
    accessModifier: TypeAccessModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "HashableExistential")

@attached(peer, names: prefixed(HashableOptional))
public macro HashableOptionalExistential(
    accessModifier: TypeAccessModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "HashableOptionalExistential")

@attached(peer, names: prefixed(HashableMutable))
public macro HashableMutableExistential(
    accessModifier: TypeAccessModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "HashableMutableExistential")

@attached(peer, names: prefixed(HashableMutableOptional))
public macro HashableMutableOptionalExistential(
    accessModifier: TypeAccessModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "HashableMutableOptionalExistential")

@attached(peer, names: prefixed(HashableSequenceOf))
public macro HashableSequenceOfExistential(
    accessModifier: TypeAccessModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "HashableSequenceOfExistential")

@attached(peer, names: prefixed(HashableMutableSequenceOf))
public macro HashableMutableSequenceOfExistential(
    accessModifier: TypeAccessModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "HashableMutableSequenceOfExistential")
