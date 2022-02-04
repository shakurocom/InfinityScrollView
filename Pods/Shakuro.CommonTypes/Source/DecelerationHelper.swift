//
//
//

import Foundation
import UIKit

public struct DecelerationHelper {

    /// - parameter initialVelocity: in points/millisecond
    public static func project(value: CGFloat, initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        guard decelerationRate < 1.0 else {
            assert(false)
            return value
        }
        return value + initialVelocity * decelerationRate / (1.0 - decelerationRate)
    }

    /// - parameter initialVelocity: in points/millisecond
    public static func project(value: CGPoint, initialVelocity: CGPoint, decelerationRate: CGPoint) -> CGPoint {
        let xProjection = project(value: value.x, initialVelocity: initialVelocity.x, decelerationRate: decelerationRate.x)
        let yProjection = project(value: value.y, initialVelocity: initialVelocity.y, decelerationRate: decelerationRate.y)
        return CGPoint(x: xProjection, y: yProjection)
    }

    /// - parameter initialVelocity: in points/millisecond
    public static func project(value: CGPoint, initialVelocity: CGPoint, decelerationRate: CGFloat) -> CGPoint {
        return project(value: value, initialVelocity: initialVelocity, decelerationRate: CGPoint(x: decelerationRate, y: decelerationRate))
    }

}
