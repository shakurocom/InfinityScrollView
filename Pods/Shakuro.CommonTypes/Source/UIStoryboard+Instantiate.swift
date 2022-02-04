//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Andrey Popov
//

import UIKit

extension UIStoryboard {

    /**
     Wrapped version of the `instantiateViewController`

     - Parameters:
         - withIdentifier: Storyboard ID of the controller, that must be created

     - Returns:
     New instance of a UIViewController.

     - Crashes with:
     `fatalError` if object with specified identifier not found in storyboard or object has different type

     - Example:
     `let exampleVC: ExampleViewController = storyboard.instantiateViewController(withIdentifier: "kExampleViewControllerStoryboardID")`
     */
    public func instantiateViewController<ControllerType: UIViewController>(withIdentifier identifier: String) -> ControllerType {
        guard let resultController: ControllerType = instantiateViewController(withIdentifier: identifier) as? ControllerType else {
            fatalError("\(type(of: self)) \(#function): \(identifier).")
        }
        return resultController
    }

}
