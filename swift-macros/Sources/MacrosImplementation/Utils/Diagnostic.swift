import Foundation
import SwiftDiagnostics
import SwiftSyntax

enum Diagnostic: DiagnosticMessage {

    /// Something unexpected has happened. Owner of this package is responsible for resolving this error.
    /// - Important: Don't create this directly but use `Diagnostic.internal(_:_:debugMessage:)` static
    /// method instead.
    case `internal`(InternalError)
    /// Macro called with an invalid argument. E.g. corrupted name identifier, or access level more accessible
    /// than the attachee declaration.
    case invalidArgument(String)
    // Invalid declaration cases below generally means that the attached macro doesn't work with the declaration
    // that is being attached to.
    /// E.g. ``WithBareCases`` can be attached only to an enum with associated values.
    case invalidDeclaration(String)
    case invalidDeclarationType(any DeclSyntaxProtocol, expected: [DeclSyntaxProtocol.Type])
    case invalidDeclarationGroupType(any DeclGroupSyntax, expected: [DeclGroupSyntax.Type])
    case uncaughtError(Error)

    var diagnosticID: SwiftDiagnostics.MessageID {
        switch self {
            case .internal:
                .init(domain: "\(Self.self)", id: "internal")
            case .invalidArgument:
                .init(domain: "\(Self.self)", id: "invalidArgument")
            case .invalidDeclaration, .invalidDeclarationType, .invalidDeclarationGroupType:
                .init(domain: "\(Self.self)", id: "invalidDeclaration")
            case .uncaughtError:
                .init(domain: "\(Self.self)", id: "uncaughtError")
        }
    }

    var message: String {
        switch self {
            case .internal(let internalError):
                String(describing: internalError)
            case .invalidArgument(let message):
                message
            case .invalidDeclaration(let message):
                message
            case .invalidDeclarationType(let invalid, let expected):
                "This marco can be attached only to \(ListFormatter.localizedString(byJoining: expected.map { "\($0.self)" })), not \(invalid.kind)."
            case .invalidDeclarationGroupType(let invalid, let expected):
                "This marco can be attached only to \(ListFormatter.localizedString(byJoining: expected.map { "\($0.self)" })), not \(invalid.kind)."
            case .uncaughtError(let error):
                "'\(type(of: error))': \(error.localizedDescription)"
        }
    }

    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
            default: .error
        }
    }
}

extension Diagnostic {

    struct InternalError: CustomStringConvertible, CustomDebugStringConvertible {
        let debugDescription: String
        let description: String
    }

    static func `internal`(_ file: String = #file, _ line: Int = #line, debugMessage: String) -> Diagnostic {
        let result = Diagnostic.internal(InternalError(
            debugDescription: debugMessage,
            description: "Internal error at \(file):\(line)."
        ))
        print(String(describing: result), String(reflecting: result))
        return result
    }
}

extension DiagnosticMessage {

    func error(at node: AttributeSyntax) -> DiagnosticsError {
        .init(diagnostics: [.init(node: node, message: self)])
    }
}

extension Error {

    func diagnosticError(at node: AttributeSyntax) -> DiagnosticsError {
        if let diagnosticsError = self as? DiagnosticsError {
            diagnosticsError
        } else {
            Diagnostic.uncaughtError(self).error(at: node)
        }
    }
}
