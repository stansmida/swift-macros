import SwiftMacros

enum WithBareCasesRun {

    static func run() {
        print(E.BareCase.self)
        print(E.BareCase.a)
        print(Foo.Bar.self)
        assert(E.a("hello").bareCase == .a)
        assert(Foo.x("dd").bar == .x)
    }
}

@WithBareCases
enum E {
    case a(String)
    case b(String, Int)
    case c
}

@WithBareCases(accessModifier: .fileprivate, typeName: "Bar")
enum Foo {
    case x(String)
    case y(String, Int)
}
