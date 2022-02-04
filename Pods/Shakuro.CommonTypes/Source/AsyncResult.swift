//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public enum AsyncResult<ResultType> {

    case success(result: ResultType)
    case failure(error: Error)

    public func removingType() -> AsyncResult<Void> {
        switch self {
        case .success: return .success(result: ())
        case .failure(let error): return .failure(error: error)
        }
    }

}

public enum CancellableAsyncResult<ResultType> {

    case success(result: ResultType)
    case cancelled
    case failure(error: Error)

    public func removingType() -> CancellableAsyncResult<Void> {
        switch self {
        case .success: return .success(result: ())
        case .cancelled: return .cancelled
        case .failure(let error): return .failure(error: error)
        }
    }

}
