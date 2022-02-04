//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation

public protocol NetworkErrorConvertible {
    func networkError() -> NetworkError
}

public struct NetworkError: PresentableError, NetworkErrorConvertible {

    public enum Value {
        case invalidHTTPStatusCode(Int)
        case apiError(status: Int, faultCode: String, errorDescription: String)
        case generalError(errorDescription: String)
    }

    public let requestURL: URL?
    public let value: Value
    public let errorDescription: String

    public var statusCode: Int? {
        switch value {
        case .invalidHTTPStatusCode(let status), .apiError(let status, _, _):
            return status
        case .generalError:
            return nil
        }
    }

    public init(value: Value, requestURL: URL?) {
        self.value = value
        self.requestURL = requestURL
        switch value {
        case .invalidHTTPStatusCode(let status):
            let codeDsc: String = HTTPURLResponse.localizedString(forStatusCode: status)
            errorDescription = NSLocalizedString("Response status code was unacceptable:", comment: "") + " \(status) (\(codeDsc))"
        case .apiError(_, _, let apiErrorDescription):
            errorDescription = apiErrorDescription
        case .generalError(let generalErrorDescription):
            errorDescription = generalErrorDescription
        }
    }

    public func networkError() -> NetworkError {
        return self
    }
}
