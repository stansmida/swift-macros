import SwiftMacros

enum BareProvidingRun {

    static func run() {
        print(E.Bare.self)
        print(E.Bare.a)
        print(Foo.Bar.self)
        assert(E.a("hello").bare == .a)
        assert(Foo.x("dd").bar == .x)
        assert(Inline.e(true, 0).bare == .e)
    }
}

@BareProviding
enum E {
    case a(String)
    case b(String, Int)
    case c
}

@BareProviding(accessModifier: .fileprivate, typeName: "Bar")
enum Foo {
    case x(String)
    case y(String, Int)
}

@BareProviding()
enum Inline {
    case a(String, Int), b(Int), c(Int, Bool)
    case d
    case e(Bool, Int), f
}
