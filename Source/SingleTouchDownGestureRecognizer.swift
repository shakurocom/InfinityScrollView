//
// All credits go to: https://stackoverflow.com/a/15629234
//

import Foundation
import UIKit

open class SingleTouchDownGestureRecognizer: UIGestureRecognizer {

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .possible {
            state = .recognized
        }
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
    }

}
