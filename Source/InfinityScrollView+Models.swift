//
// Copyright (c) 2020 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import CoreGraphics
import Foundation
import UIKit

extension InfinityScrollView {

    public enum SwipeDirection {

        /// User dragged here and there but end drag on the same item he started.
        case none

        /// User ended dragging on item to the left of the starting item
        case left

        /// User ended dragging on item to the right of the starting item
        case right

    }

    public enum SnapAnimation {

        /// No animation - hard jump to projected offset
        case none

        /// Default animation of UIScrollView
        case scrollView

        /// Animation curve with given name (ex.: easeIn)
        case curve(duration: CFTimeInterval, name: CAMediaTimingFunctionName)

        /// Dumped spring. See `CASpringAnimation` for parameters description.
        /// Initial velocity obtained from drag.
        /// - warning: Very bouncy spring on energetic (high velocity) drag can lead to user see not yet tiled-out area.
        case spring(mass: CGFloat, stiffness: CGFloat, damping: CGFloat)

        /// example parameters for spring animation
        public static let defaultSpring = SnapAnimation.spring(mass: 1, stiffness: 40, damping: 8)

    }

    public enum SingleItemBehavior {

        /// Single item is tiled (as if there is more than one item)
        case tile

        /// No tiling.
        /// Scroll area set to the width of item.
        /// UIScrollview's bounce will be enabled for user drag.
        case bounce

        /// No tiling.
        /// Scroll area set to the width of item.
        /// UIScrollview's bounce will be disabled for user drag.
        case noBounce

    }

    internal struct NearestVisibleCenterItemData {
        internal let anchorOffsetX: CGFloat
        internal let tileCenterX: CGFloat
        internal let itemIndex: Int
        internal let tileIndex: Int
    }

    internal struct AnimationData {
        internal let projectedContentOffsetX: CGFloat
        internal let nearestItemData: NearestVisibleCenterItemData
        internal let initialVelocityX: CGFloat
    }

}
