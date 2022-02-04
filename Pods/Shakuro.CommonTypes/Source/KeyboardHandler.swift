//
// Copyright (c) 2017-2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

/**
 Utility to handle keyboard appearing & disappearing "in one line".
 */
public class KeyboardHandler {

    /**
     if `false` notifications about keyboard changes will be skipped.
     Default value is `false`.
     */
    public var isActive: Bool = false

    private let heightDidChangeHandler: (KeyboardChange) -> Void
    private var observerTokens: [NSObjectProtocol]
    private let isCurveHackEnabled: Bool

    // MARK: - Initialization

    /**
     - parameter enableCurveHack: enables hack to obtain animation curve of the keyboard.
     - parameter heightDidChange: main handler of keyboard change, will be called on main thread.
     */
    public init(enableCurveHack: Bool, heightDidChange handler: @escaping (_ change: KeyboardChange) -> Void) {
        heightDidChangeHandler = handler
        observerTokens = []
        isCurveHackEnabled = enableCurveHack

        let center: NotificationCenter = NotificationCenter.default
        let willShowKeyboardObserverToken = center.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: nil,
            using: { (notification) in
                self.processKeyboardNotification(notification)
        })
        observerTokens.append(willShowKeyboardObserverToken)
        let willHideKeyboardObserverToken = center.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: nil,
            using: { (notification) in
                self.processKeyboardNotification(notification)
        })
        observerTokens.append(willHideKeyboardObserverToken)
    }

    deinit {
        let center: NotificationCenter = NotificationCenter.default
        for token in observerTokens {
            center.removeObserver(token)
        }
    }

    // MARK: - Private

    private func processKeyboardNotification(_ notification: Notification) {
        guard isActive else {
            return
        }
        let change = KeyboardChange(userInfo: notification.userInfo, enableCurveHack: isCurveHackEnabled)
        heightDidChangeHandler(change)
    }

}

extension KeyboardHandler {

    private enum Constant {
        static let defaultAnimationDuration: TimeInterval = 0.25
        static let defaultAnimationCurve: UIView.AnimationCurve = .easeIn
    }

    public struct KeyboardChange {

        public let newHeight: CGFloat
        public let animationDuration: TimeInterval
        public let animationCurve: UIView.AnimationCurve

        internal init(userInfo: [AnyHashable: Any]?, enableCurveHack: Bool) {
            if let keyboardFrame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                let screenSize: CGRect = UIScreen.main.bounds
                newHeight = screenSize.height - keyboardFrame.origin.y
            } else {
                newHeight = 0.0
            }
            if let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.floatValue, duration > 0 {
                animationDuration = TimeInterval(duration)
            } else {
                animationDuration = Constant.defaultAnimationDuration
            }
            if enableCurveHack {
                // HACK: UIViewAnimationCurve doesn't expose the keyboard animation used (curveValue = 7),
                // so UIViewAnimationCurve(rawValue: curveValue) returns nil. As a workaround, get a
                // reference to an EaseIn curve, then change the underlying pointer data with that ref.
                var curve = Constant.defaultAnimationCurve
                if let curveValue = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int {
                    NSNumber(value: curveValue).getValue(&curve)
                }
                animationCurve = curve
            } else {
                animationCurve = Constant.defaultAnimationCurve
            }
        }

    }

}
