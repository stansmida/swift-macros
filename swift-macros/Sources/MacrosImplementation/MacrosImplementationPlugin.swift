import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HashableExistential.self,
        HashableOptionalExistential.self,
        HashableMutableExistential.self,
        HashableMutableOptionalExistential.self,
        HashableSequenceOfExistential.self,
        HashableMutableSequenceOfExistential.self,
        WithBareCases.self,
    ]
}
