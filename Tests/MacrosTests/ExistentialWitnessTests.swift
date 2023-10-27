import Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MacrosImplementation)
import MacrosImplementation

final class SelfWitnessTests: XCTestCase {

    func testHashableExistential() throws {
        let container1 = PContainer(p: P1(value: 0))
        let container1Copy = container1
        XCTAssertEqual(container1, container1Copy)
        XCTAssertEqual(container1.hashValue, container1Copy.hashValue)
        let container2 = PContainer(p: P2(value: 0))
        XCTAssertNotEqual(container1, container2)
        XCTAssertNotEqual(container1.hashValue, container2.hashValue)
    }

    func testHashableOptionalExistential() throws {
        var container1 = PContainer(pO: nil, pVarO: P1(value: 0))
        let container1Copy = container1
        XCTAssertEqual(container1, container1Copy)
        XCTAssertEqual(container1.hashValue, container1Copy.hashValue)
        XCTAssertEqual(container1.$pO, container1Copy.$pO)
        XCTAssertEqual(container1.$pO.hashValue, container1Copy.$pO.hashValue)
        XCTAssertEqual(container1.$pVarO, container1Copy.$pVarO)
        XCTAssertEqual(container1.$pVarO.hashValue, container1Copy.$pVarO.hashValue)
        let container2 = PContainer(pO: nil, pVarO: P2(value: 0))
        XCTAssertNotEqual(container1, container2)
        XCTAssertNotEqual(container1.hashValue, container2.hashValue)
        XCTAssertEqual(container1.$pO, container2.$pO)
        XCTAssertEqual(container1.$pO.hashValue, container2.$pO.hashValue)
        XCTAssertNotEqual(container1.$pVarO, container2.$pVarO)
        XCTAssertNotEqual(container1.$pVarO.hashValue, container2.$pVarO.hashValue)
        container1.pVarO = P1(value: 1)
        container1.pVarO = nil
    }

    func testHashableMutableExistential() throws {
        var container = PContainer(pVar: P1(value: 0))
        let newValue = P2(value: 0)
        container.pVar = newValue
        XCTAssertTrue(container.pVar.isEqual(to: newValue))
    }

    func testHashableSequenceOfExistential() throws {
        let p = P1(value: 0)
        let container = PContainer(pA: [p], pCOO: CollectionOfOne(p), pAVar: [p])
        let containerCopy = container
        XCTAssertEqual(container, containerCopy)
        // Text that same sequence types with same elements have same hash.
        XCTAssertEqual(container.$pA.hashValue, container.$pAVar.hashValue)
        // Test that different sequence types with same elements have different hash.
        XCTAssertNotEqual(container.$pA.hashValue, container.$pCOO.hashValue)
    }

    func testHashableMutableSequenceOfExistential() throws {
        var container = PContainer(pAVar: [P1(value: 0)])
        let newValue = P2(value: 0)
        container.pAVar[0] = newValue
        XCTAssertTrue(container.pAVar.first!.isEqual(to: newValue))
    }

    func testHashableExpansions() throws {
        assertMacroExpansion(
            """
            @HashableExistential(accessModifier: .private)
            @HashableOptionalExistential
            @HashableMutableExistential
            @HashableMutableOptionalExistential
            @HashableSequenceOfExistential
            @HashableMutableSequenceOfExistential(accessModifier: .internal)
            protocol P: Hashable {}
            """,
            expandedSource: """
            protocol P: Hashable {}

            @propertyWrapper
            private struct HashableP: Hashable {
                fileprivate init(wrappedValue: any P) {
                    self.wrappedValue = wrappedValue
                }
                let wrappedValue: any P
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.wrappedValue.isEqual(to: rhs.wrappedValue)
                }
                func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(type(of: wrappedValue)))
                    hasher.combine(wrappedValue)
                }
            }

            @propertyWrapper
            struct HashableOptionalP: Hashable {

                let wrappedValue: (any P)?
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    if let lhs = lhs.wrappedValue, let rhs = rhs.wrappedValue {
                        lhs.isEqual(to: rhs)
                    } else {
                        lhs.wrappedValue == nil && rhs.wrappedValue == nil
                    }
                }
                func hash(into hasher: inout Hasher) {
                    if let wrappedValue {
                        hasher.combine(ObjectIdentifier(type(of: wrappedValue)))
                        hasher.combine(wrappedValue)
                    } else {
                        hasher.combine(ObjectIdentifier(type(of: wrappedValue)))
                    }
                }
            }

            @propertyWrapper
            struct HashableMutableP: Hashable {

                var wrappedValue: any P
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.wrappedValue.isEqual(to: rhs.wrappedValue)
                }
                func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(type(of: wrappedValue)))
                    hasher.combine(wrappedValue)
                }
            }

            @propertyWrapper
            struct HashableMutableOptionalP: Hashable {

                var wrappedValue: (any P)?
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    if let lhs = lhs.wrappedValue, let rhs = rhs.wrappedValue {
                        lhs.isEqual(to: rhs)
                    } else {
                        lhs.wrappedValue == nil && rhs.wrappedValue == nil
                    }
                }
                func hash(into hasher: inout Hasher) {
                    if let wrappedValue {
                        hasher.combine(ObjectIdentifier(type(of: wrappedValue)))
                        hasher.combine(wrappedValue)
                    } else {
                        hasher.combine(ObjectIdentifier(type(of: wrappedValue)))
                    }
                }
            }

            @propertyWrapper
            struct HashableSequenceOfP<T>: Hashable where T: Sequence, T.Element == any P {

                let wrappedValue: T
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    zip(lhs.wrappedValue, rhs.wrappedValue).allSatisfy {
                        // Ideally `$0.0.isEqual(to: $0.1)` but ATM there seems to be a bug preventing to compile this.
                        ();
                        return $0.0.isEqual(to: $0.1)
                    }
                }
                func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(T.self))
                    for element in wrappedValue {
                        hasher.combine(element)
                    }
                }
            }

            @propertyWrapper
            internal struct HashableMutableSequenceOfP<T>: Hashable where T: Sequence, T.Element == any P {

                var wrappedValue: T
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    zip(lhs.wrappedValue, rhs.wrappedValue).allSatisfy {
                        // Ideally `$0.0.isEqual(to: $0.1)` but ATM there seems to be a bug preventing to compile this.
                        ();
                        return $0.0.isEqual(to: $0.1)
                    }
                }
                func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(T.self))
                    for element in wrappedValue {
                        hasher.combine(element)
                    }
                }
            }
            """,
            macros: [
                "HashableExistential": HashableExistential.self,
                "HashableOptionalExistential": HashableOptionalExistential.self,
                "HashableMutableExistential": HashableMutableExistential.self,
                "HashableMutableOptionalExistential": HashableMutableOptionalExistential.self,
                "HashableSequenceOfExistential": HashableSequenceOfExistential.self,
                "HashableMutableSequenceOfExistential": HashableMutableSequenceOfExistential.self
            ]
        )
    }

    func testHashableExpansionsPublic() throws {
        assertMacroExpansion(
            """
            @HashableExistential(accessModifier: .fileprivate)
            @HashableMutableExistential
            @HashableSequenceOfExistential
            @HashableMutableSequenceOfExistential(accessModifier: .internal)
            public protocol P: Hashable {}
            """,
            expandedSource: """
            public protocol P: Hashable {}

            @propertyWrapper
            fileprivate struct HashableP: Hashable {

                let wrappedValue: any P
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.wrappedValue.isEqual(to: rhs.wrappedValue)
                }
                func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(type(of: wrappedValue)))
                    hasher.combine(wrappedValue)
                }
            }

            @propertyWrapper
            public struct HashableMutableP: Hashable {
                public init(wrappedValue: any P) {
                    self.wrappedValue = wrappedValue
                }
                public var wrappedValue: any P
                public var projectedValue: Self {
                    self
                }
                public static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.wrappedValue.isEqual(to: rhs.wrappedValue)
                }
                public func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(type(of: wrappedValue)))
                    hasher.combine(wrappedValue)
                }
            }

            @propertyWrapper
            public struct HashableSequenceOfP<T>: Hashable where T: Sequence, T.Element == any P {
                public init(wrappedValue: T) {
                    self.wrappedValue = wrappedValue
                }
                public let wrappedValue: T
                public var projectedValue: Self {
                    self
                }
                public static func == (lhs: Self, rhs: Self) -> Bool {
                    zip(lhs.wrappedValue, rhs.wrappedValue).allSatisfy {
                        // Ideally `$0.0.isEqual(to: $0.1)` but ATM there seems to be a bug preventing to compile this.
                        ();
                        return $0.0.isEqual(to: $0.1)
                    }
                }
                public func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(T.self))
                    for element in wrappedValue {
                        hasher.combine(element)
                    }
                }
            }

            @propertyWrapper
            internal struct HashableMutableSequenceOfP<T>: Hashable where T: Sequence, T.Element == any P {

                var wrappedValue: T
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    zip(lhs.wrappedValue, rhs.wrappedValue).allSatisfy {
                        // Ideally `$0.0.isEqual(to: $0.1)` but ATM there seems to be a bug preventing to compile this.
                        ();
                        return $0.0.isEqual(to: $0.1)
                    }
                }
                func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(T.self))
                    for element in wrappedValue {
                        hasher.combine(element)
                    }
                }
            }
            """,
            macros: [
                "HashableExistential": HashableExistential.self,
                "HashableMutableExistential": HashableMutableExistential.self,
                "HashableSequenceOfExistential": HashableSequenceOfExistential.self,
                "HashableMutableSequenceOfExistential": HashableMutableSequenceOfExistential.self
            ]
        )
    }

    func testHashableExpansionsPrivate() throws {
        assertMacroExpansion(
            """
            @HashableExistential
            @HashableMutableSequenceOfExistential
            private protocol P: Hashable {}
            """,
            expandedSource: """
            private protocol P: Hashable {}

            @propertyWrapper
            private struct HashableP: Hashable {
                fileprivate init(wrappedValue: any P) {
                    self.wrappedValue = wrappedValue
                }
                let wrappedValue: any P
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.wrappedValue.isEqual(to: rhs.wrappedValue)
                }
                func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(type(of: wrappedValue)))
                    hasher.combine(wrappedValue)
                }
            }

            @propertyWrapper
            private struct HashableMutableSequenceOfP<T>: Hashable where T: Sequence, T.Element == any P {
                fileprivate init(wrappedValue: T) {
                    self.wrappedValue = wrappedValue
                }
                var wrappedValue: T
                var projectedValue: Self {
                    self
                }
                static func == (lhs: Self, rhs: Self) -> Bool {
                    zip(lhs.wrappedValue, rhs.wrappedValue).allSatisfy {
                        // Ideally `$0.0.isEqual(to: $0.1)` but ATM there seems to be a bug preventing to compile this.
                        ();
                        return $0.0.isEqual(to: $0.1)
                    }
                }
                func hash(into hasher: inout Hasher) {
                    hasher.combine(ObjectIdentifier(T.self))
                    for element in wrappedValue {
                        hasher.combine(element)
                    }
                }
            }
            """,
            macros: [
                "HashableExistential": HashableExistential.self,
                "HashableMutableSequenceOfExistential": HashableMutableSequenceOfExistential.self
            ]
        )
    }

    func testDiagnosticAccessLevel() {
        assertMacroExpansion(
            """
            @HashableExistential(accessModifier: .public)
            protocol P: Hashable {}
            """,
            expandedSource: """
            protocol P: Hashable {}
            """,
            diagnostics: [.init(message: "Expansion type cannot have less restrictive access than its anchor declaration.", line: 1, column: 1)],
            macros: ["HashableExistential": HashableExistential.self]
        )
    }
}

// TODO: Can be nested to the below from Swift 5.10 (https://github.com/apple/swift-evolution/blob/main/proposals/0404-nested-protocols.md)
@HashableExistential(accessModifier: .private)
@HashableOptionalExistential
@HashableMutableExistential(accessModifier: .internal)
@HashableMutableOptionalExistential(accessModifier: .private)
@HashableSequenceOfExistential
@HashableMutableSequenceOfExistential
public protocol P: Hashable {}

extension SelfWitnessTests {

    struct P1: P {
        let value: Int
    }

    struct P2: P {
        let value: Int
    }

    private struct PContainer: Hashable {

        init(
            p: some P = P1(value: 0),
            pO: (any P)? = nil,
            pVar: some P = P1(value: 0),
            pVarO: (any P)? = nil,
            pA: [any P] = [P1(value: 0)],
            pCOO: CollectionOfOne<any P> = CollectionOfOne(P1(value: 0)),
            pAVar: [any P] = [P1(value: 0)]
        ) {
            _p = HashableP(wrappedValue: p)
            _pO = HashableOptionalP(wrappedValue: pO)
            _pVar = HashableMutableP(wrappedValue: pVar)
            _pVarO = HashableMutableOptionalP(wrappedValue: pVarO)
            _pA = HashableSequenceOfP(wrappedValue: pA)
            _pCOO = HashableSequenceOfP(wrappedValue: pCOO)
            _pAVar = HashableMutableSequenceOfP(wrappedValue: pAVar)
        }

        @HashableP
        fileprivate var p: any P

        @HashableOptionalP
        var pO: (any P)?

        @HashableMutableP
        var pVar: any P

        @HashableMutableOptionalP
        var pVarO: (any P)?

        @HashableSequenceOfP
        var pA: [any P]

        @HashableSequenceOfP
        var pCOO: CollectionOfOne<any P>

        @HashableMutableSequenceOfP
        var pAVar: [any P]
    }
}

#endif
