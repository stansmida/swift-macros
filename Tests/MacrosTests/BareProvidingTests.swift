import SwiftMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MacrosImplementation)
import MacrosImplementation
#endif

final class BareProvidingExpansionTests: XCTestCase {

    #if canImport(MacrosImplementation)

    // Test the marco without any parameters, with completely omitted access level explicitly (from the parameter)
    // and implicitly (from the enum declaration).
    func testExpansionWithoutParameters() throws {
        assertMacroExpansion(
            """
            @BareProviding
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

                enum Bare: Hashable {
                    case a
                    case b
                    case cA
                }

                var bare: Bare {
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
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testExpansionWithInlineCasesDeclaration() throws {
        assertMacroExpansion(
            """
            @BareProviding
            enum E {
                case a(A), b(B, String), c
                case d, e(Bool)
                case f
            }
            """,
            expandedSource: """
            enum E {
                case a(A), b(B, String), c
                case d, e(Bool)
                case f

                enum Bare: Hashable {
                    case a
                    case b
                    case c
                    case d
                    case e
                    case f
                }

                var bare: Bare {
                    switch self {
                    case .a:
                        .a
                    case .b:
                        .b
                    case .c:
                        .c
                    case .d:
                        .d
                    case .e:
                        .e
                    case .f:
                        .f
                    }
                }
            }
            """,
            macros: ["BareProviding": BareProviding.self]
        )
    }

    /// Test explicitly nil access - uses same access level modifier as the enum that the macro is attached to.
    /// Test custom type name.
    /// Test enum with intervening elements.
    func testExpansionWithParameters1() throws {
        assertMacroExpansion(
            """
            @BareProviding(accessModifier: nil, typeName: "Foo")
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
            macros: ["BareProviding": BareProviding.self]
        )
    }

    // Test the marco with access parameter only.
    func testExpansionWithParameters2() throws {
        assertMacroExpansion(
            """
            @BareProviding(accessModifier: .fileprivate)
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

                fileprivate enum Bare: Hashable {
                    case a
                    case b
                    case cA
                }

                fileprivate var bare: Bare {
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
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testDiagnosticInvalidAccessModifier() {
        assertMacroExpansion(
            """
            @BareProviding(accessModifier: TypeAccessModifier.public)
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
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testDiagnosticNoAssociatedValue() {
        assertMacroExpansion(
            """
            @BareProviding
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
            diagnostics: [.init(message: "'@BareProviding' can only be attached to an enum with associated values.", line: 1, column: 1)],
            macros: ["BareProviding": BareProviding.self]
        )
    }

    func testDiagnosticCorruptedTypeName() {
        assertMacroExpansion(
            """
            @BareProviding(typeName: "Oh uh")
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
            macros: ["BareProviding": BareProviding.self]
        )
    }

    #else

    func testExpansions() throws {
        XCTSkip("macros are only supported when running tests for the host platform")
    }

    #endif
}

final class BareProvidingTests: XCTestCase {

    func testBareProviding() {
        XCTAssertEqual(E.a("hello").bare, .a)
        XCTAssertEqual(Foo.x("dd").bar, .x)
    }
}

@BareProviding
enum E {
    case a(String)
    case b(String, Int)
    case c
}

@BareProviding(accessModifier: TypeAccessModifier.fileprivate, typeName: "Bar")
enum Foo {
    case x(String)
    case y(String, Int)
}
