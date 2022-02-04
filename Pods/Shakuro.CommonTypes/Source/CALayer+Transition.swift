//
//
//  Copyright © 2019 Shakuro. All rights reserved.
//

import UIKit

extension CALayer {

    public enum TransitionAnimationConstant {
        public static let animationKey: String = "custom_layer_transition"
        public static let defaultTransitionType: CATransitionType = .fade
        public static let defaultDuration: CFTimeInterval = 0.15
        public static let defaultTimingFunction: CAMediaTimingFunctionName = .easeInEaseOut
    }

    public func addTransitionAnimation(type: CATransitionType = TransitionAnimationConstant.defaultTransitionType,
                                       subType: CATransitionSubtype? = nil,
                                       duration: CFTimeInterval = TransitionAnimationConstant.defaultDuration,
                                       timingFunctionName: CAMediaTimingFunctionName = TransitionAnimationConstant.defaultTimingFunction) {
        let transition: CATransition = CATransition()
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: timingFunctionName)
        transition.type = type
        transition.subtype = subType
        transition.isRemovedOnCompletion = true
        add(transition, forKey: TransitionAnimationConstant.animationKey)
    }

}
