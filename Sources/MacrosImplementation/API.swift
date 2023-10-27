import SwiftSyntax

enum BindingSpecifier: String {
    case `let`, `var`
}

public enum TypeAccessModifier: String {

    case `open`, `public`, `internal`, `fileprivate`, `private`

    static var `default`: Self { .internal }
    static let parameterLabel = "accessModifier"
}

extension TypeAccessModifier: Comparable {

    /// More restrictive < more accessible.
    public static func < (lhs: TypeAccessModifier, rhs: TypeAccessModifier) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
            case .open: 4
            case .public: 3
            case .internal: 2
            case .fileprivate: 1
            case .private: 0
        }
    }
}

/// Working with SwiftSyntax.
extension TypeAccessModifier {

    init?(_ declModifierSyntax: DeclModifierSyntax) {
        switch declModifierSyntax.name.tokenKind {
            case .keyword(.open): self = .open
            case .keyword(.public): self = .public
            case .keyword(.internal): self = .internal
            case .keyword(.fileprivate): self = .fileprivate
            case .keyword(.private): self = .private
            default: return nil
        }
    }

    var keyword: Keyword {
        switch self {
            case .open: .open
            case .public: .public
            case .internal: .internal
            case .fileprivate: .fileprivate
            case .private: .private
        }
    }
}
