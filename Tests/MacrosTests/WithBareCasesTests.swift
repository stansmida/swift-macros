import SwiftMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MacrosImplementation)
import MacrosImplementation

final class BareCasesMacroTests: XCTestCase {

    func testBareCases() {
        XCTAssertEqual(E.a("hello").bareCase, .a)
        XCTAssertEqual(Foo.x("dd").bar, .x)
    }

    // Test the marco without any parameters, with completely omitted access level explicitly (from the parameter)
    // and implicitly (from the enum declaration).
    func testExpansionWithoutParameters() throws {
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
    func testExpansionWithParameters1() throws {
        assertMacroExpansion(
            """
            @WithBareCases(accessModifier: nil, typeName: "Foo")
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
    func testExpansionWithParameters2() throws {
        assertMacroExpansion(
            """
            @WithBareCases(accessModifier: .fileprivate)
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

    func testDiagnosticInvalidAccessModifier() {
        assertMacroExpansion(
            """
            @WithBareCases(accessModifier: TypeAccessModifier.public)
            enum WithInvalidAccessModifier {
                case a(Void)
            }
            """,
            expandedSource:
            """
            enum WithInvalidAccessModifier {
                case a(Void)
            }
            """,
            diagnostics: [.init(message: "Expansion type cannot have less restrictive access than its anchor declaration.", line: 1, column: 1)],
            macros: ["WithBareCases": WithBareCases.self]
        )
    }

    func testDiagnosticNoAssociatedValue() {
        assertMacroExpansion(
            """
            @WithBareCases
            enum NoAssociatedValue {
                case a
            }
            """,
            expandedSource:
            """
            enum NoAssociatedValue {
                case a
            }
            """,
            diagnostics: [.init(message: "'@WithBareCases' can only be attached to an enum with associated values.", line: 1, column: 1)],
            macros: ["WithBareCases": WithBareCases.self]
        )
    }

    func testDiagnosticCorruptedTypeName() {
        assertMacroExpansion(
            """
            @WithBareCases(typeName: "Oh uh")
            enum Whoops {
                case a(String)
            }
            """,
            expandedSource:
            """
            enum Whoops {
                case a(String)
            }
            """,
            diagnostics: [.init(message: "Invalid type name: 'Oh uh'.", line: 1, column: 1)],
            macros: ["WithBareCases": WithBareCases.self]
        )
    }
}

private extension BareCasesMacroTests {

    @WithBareCases
    enum E {
        case a(String)
        case b(String, Int)
        case c
    }

    @WithBareCases(accessModifier: TypeAccessModifier.fileprivate, typeName: "Bar")
    enum Foo {
        case x(String)
        case y(String, Int)
    }
}

#endif
