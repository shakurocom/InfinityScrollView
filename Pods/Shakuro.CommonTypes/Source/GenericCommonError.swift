//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
//
//

import Foundation

public enum GenericCommonError: Int, PresentableError {

    case notAuthorized = 101
    case unknown = 102

    public var errorDescription: String {
        let dsc: String
        switch self {
        case .notAuthorized:
            dsc = NSLocalizedString("The operation could not be completed. Not authorized.", comment: "")
        case .unknown:
            dsc = NSLocalizedString("The operation could not be completed.", comment: "")
        }
        return dsc
    }

}
