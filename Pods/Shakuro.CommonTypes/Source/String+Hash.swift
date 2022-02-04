//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

extension String {

    public func SHA256() -> String? {
        return data(using: String.Encoding.utf8)?.SHA256String()
    }

    public func SHA512() -> String? {
        return data(using: String.Encoding.utf8)?.SHA512()
    }

    public func MD5() -> String? {
        return data(using: String.Encoding.utf8)?.MD5()
    }

}
