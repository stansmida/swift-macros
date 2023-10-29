import SwiftMacros

// - MARK: @SelfWitness

@HashableExistential(accessModifier: .fileprivate)
@HashableOptionalExistential
@HashableMutableSequenceOfExistential
public protocol P: Hashable {}

struct P1: P {
    let value: Int
}

struct P2: P {
    let value: Int
}

struct PContainer: Hashable {
    
    init(p: some P = P1(value: 0), pO: (any P)? = nil, ps: [any P] = []) {
        _p = HashableP(wrappedValue: p)
        _pO = HashableOptionalP(wrappedValue: pO)
        _ps = HashableMutableSequenceOfP(wrappedValue: ps)
    }

    @HashableP
    fileprivate var p: any P

    @HashableOptionalP
    var pO: (any P)?

    @HashableMutableSequenceOfP
    var ps: [any P]
}

assert(Set([PContainer(p: P1(value: 0)), PContainer(p: P2(value: 0))]).count == 2)
assert(PContainer(p: P1(value: 0)) == PContainer(p: P1(value: 0)))
assert(PContainer(p: P1(value: 0)) != PContainer(p: P1(value: 1)))
assert(PContainer(p: P1(value: 0)) != PContainer(p: P2(value: 0)))
assert(PContainer(ps: [P1(value: 0)]).hashValue == PContainer(ps: [P1(value: 0)]).hashValue)
var mutableContainer = PContainer(ps: [P1(value: 0)])
let newP0 = P2(value: 0)
mutableContainer.ps[0] = newP0
assert(mutableContainer.ps.first!.isEqual(to: newP0))
assert(PContainer().$p.hashValue == HashableP(wrappedValue: P1(value: 0)).hashValue)


// - MARK: @WithBareCases

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

assert(E.a("hello").bareCase == .a)
assert(Foo.x("dd").bar == .x)
