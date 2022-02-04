//
// Copyright (c) 2018-2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

extension NSLocking {

    public func execute<ResultType>(_ closure: () throws -> ResultType) rethrows -> ResultType {
        lock()
        defer { unlock() }
        return try closure()
    }

}
