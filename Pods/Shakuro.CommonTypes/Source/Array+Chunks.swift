//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//
// original: https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
//

import Foundation

extension Array {

    // Split array into multiple arrays of given size.
    public func chunked(chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: chunkSize).map({ (startIndex) -> [Element] in
            Array(self[startIndex..<Swift.min(startIndex + chunkSize, count)])
        })
    }

}
