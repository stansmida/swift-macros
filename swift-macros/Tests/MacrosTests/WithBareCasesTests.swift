import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MacrosImplementation)
import MacrosImplementation

final class BareCasesMacroTests: XCTestCase {

    // Test the marco without any parameters, with completely omitted access level explicitly (from the parameter)
    // and implicitly (from the enum declaration).
    func testMacroWithoutParameters() throws {
        assertMacroExpansion(
            """
            @WithBareCases
            enum E {
                case a(A)
                case b(B, String)
                case cA
            }
            """,
            expandedSource: """
            enum E {
                case a(A)
                case b(B, String)
                case cA

                enum BareCase: Hashable {
                    case a
                    case b
                    case cA
                }

                var bareCase: BareCase {
                    switch self {
                    case .a:
                        .a
                    case .b:
                        .b
                    case .cA:
                        .cA
                    }
                }
            }
            """,
            macros: ["WithBareCases": WithBareCases.self]
        )
    }

    /// Test explicitly nil access - uses same access level modifier as the enum that the macro is attached to.
    /// Test custom type name.
    /// Test enum with intervening elements.
    func testMacroWithParameters1() throws {
        assertMacroExpansion(
            """
            @WithBareCases(access: nil, typeName: "Foo")
            public enum E: Whateverable {
                enum Intervening {}
                case a(A)
                var interveningDeclaration: String { "hello" }
                /// intervening trivia :-)
                case b(B, String)
            }
            """,
            expandedSource: """
            public enum E: Whateverable {
                enum Intervening {}
                case a(A)
                var interveningDeclaration: String { "hello" }
                /// intervening trivia :-)
                case b(B, String)

                public enum Foo: Hashable {
                    case a
                    case b
                }

                public var foo: Foo {
                    switch self {
                    case .a:
                        .a
                    case .b:
                        .b
                    }
                }
            }
            """,
            macros: ["WithBareCases": WithBareCases.self]
        )
    }

    // Test the marco with access parameter only.
    func testMacroWithParameters2() throws {
        assertMacroExpansion(
            """
            @WithBareCases(access: .fileprivate)
            enum E {
                case a(A)
                case b(B, String)
                case cA
            }
            """,
            expandedSource: """
            enum E {
                case a(A)
                case b(B, String)
                case cA

                fileprivate enum BareCase: Hashable {
                    case a
                    case b
                    case cA
                }

                fileprivate var bareCase: BareCase {
                    switch self {
                    case .a:
                        .a
                    case .b:
                        .b
                    case .cA:
                        .cA
                    }
                }
            }
            """,
            macros: ["WithBareCases": WithBareCases.self]
        )
    }
}

#endif
