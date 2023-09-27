import Macros

@WithBareCases
enum E {
    case a(String)
    case b(String, Int)
}

@WithBareCases(access: .fileprivate, typeName: "Bar")
enum Foo {
    case x(String)
    case y(String, Int)
}

print(E.a("hello").bareCase == .a)
print(Foo.x("dd").bar == .x)
