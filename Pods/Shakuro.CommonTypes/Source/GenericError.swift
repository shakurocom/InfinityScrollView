//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation

// MARK: - PresentableError

public protocol PresentableError: Error {
    var errorDescription: String { get }
}

// MARK: - GenericError

public typealias DefaultGenericError = GenericError<ErrorInterpreter>

public protocol GenericErrorProtocol: PresentableError {

    var value: Error { get }
    var errorDescription: String { get }

    func getValue<T>() -> T?

}

public struct GenericError<Interpreter: ErrorInterpreterProtocol>: GenericErrorProtocol {

    public let value: Error

    public var errorDescription: String {
        return Interpreter.generateDescription(value)
    }

    public init(_ value: Error) {
        self.value = value
    }

    public func getValue<T>() -> T? {
        return value as? T ?? (value as? GenericErrorProtocol)?.getValue()
    }

    public func isNotFoundError() -> Bool {
        return Interpreter.isNotFoundError(self)
    }

    public func isNotAuthorizedError() -> Bool {
        return Interpreter.isNotAuthorizedError(self)
    }

    public func isCancelledError() -> Bool {
        return Interpreter.isCancelledError(self)
    }

    public func isRequestTimedOutError() -> Bool {
        return Interpreter.isRequestTimedOutError(self)
    }

    public func isConnectionError() -> Bool {
        return Interpreter.isConnectionError(self)
    }

    public func isInternalServerError() -> Bool {
        return Interpreter.isInternalServerError(self)
    }

}
