//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Andrey Popov
//

import Foundation
import UIKit

extension UIApplication {

    public static let bundleIdentifier: String = {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("\(String(describing: self)) - \(#function): can't read bundle identifier from bundle: \(Bundle.main).")
        }
        return bundleIdentifier
    }()

}
