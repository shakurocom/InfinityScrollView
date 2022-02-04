//
//
//

import CoreGraphics
import Foundation

extension CGPoint {

    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
    }

    func distanceSquared(to point: CGPoint) -> CGFloat {
        return pow((point.x - x), 2) + pow((point.y - y), 2)
    }

}
