@_exported import enum SwiftSyntaxExtras.TypeAccessModifier

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
@attached(member, names: named(Bare), named(bare))
public macro BareProviding(
    accessModifier: TypeAccessModifier? = nil
) = #externalMacro(module: "MacrosImplementation", type: "BareProviding")

/// For example
///
///     @BareProviding(typeName: "Foo")
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
///         enum Foo: Hashable {
///             case a
///             case b
///         }
///
///         var foo: Foo {
///             switch self {
///                 case .a:
///                     .a
///                 case .b:
///                     .b
///             }
///         }
///     }
@attached(member, names: arbitrary)
public macro BareProviding(
    accessModifier: TypeAccessModifier? = nil,
    typeName: String
) = #externalMacro(module: "MacrosImplementation", type: "BareProviding")
