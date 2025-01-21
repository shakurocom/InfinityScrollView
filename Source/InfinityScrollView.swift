//
// Copyright (c) 2020 Shakuro (https://shakuro.com/)
// Sergey Popov, Sergey Laschuk
//

import Foundation
import Shakuro_CommonTypes
import UIKit

public protocol InfinityScrollViewDataSource: AnyObject {

    /// - parameter infinityScrollView: caller.
    /// - returns: number of elementes in infinity scroll.
    ///     Negative value will throw assert (debug) or be rounded to zero (release).
    func infinityScrollViewNumberOfItems(_ infinityScrollView: InfinityScrollView) -> Int

    /// - parameter infinityScrollView: caller.
    /// - parameter index: index of item.
    /// - returns: width of item at index.
    ///     Behaviour for zero/negative values is not defined (please refrain)
    ///     Height will be equal to the height of InfinityScrollView.
    func infinityScrollView(_ infinityScrollView: InfinityScrollView, widthForItemAtIndex index: Int) -> CGFloat

    /// - parameter infinityScrollView: caller.
    /// - parameter index: index of item.
    /// - parameter size: size, that will be set to view.
    /// - returns: setted up view for displaying item
    ///
    /// `.intrinsicContentSize` is not supported.
    /// Height will be always equal to height of InfinityScrollView itself.
    /// Consider creating etalon view and calculating dynamic width inside `infinityScrollView(:,widthForItemAtIndex:)`.
    ///
    /// You can perform some additional configuration of returned view, depending on the provided size.
    func infinityScrollView(_ infinityScrollView: InfinityScrollView, viewForItemAtIndex index: Int, size: CGSize) -> UIView

}

public protocol InfinityScrollViewDelegate: AnyObject {

    /// Will not be reported if there are no items in InfinityScrollView
    func infinityScrollView(_ infinityScrollView: InfinityScrollView,
                            willEndSwipeOnItemAtIndex itemIndex: Int,
                            swipeDirection: InfinityScrollView.SwipeDirection)

    /// Will be reported even if deceleration is disabled.
    func infinityScrollView(_ infinityScrollView: InfinityScrollView, didEndDeceleratingOnItemAtIndex itemIndex: Int, wasAborted: Bool)

    /// User tapped specific item.
    /// Tap to stop deceleration animation do not count.
    func infinityScrollView(_ infinityScrollView: InfinityScrollView, didSelectItemAtIndex itemIndex: Int)

}

/// CollectView-like control. Handles infinity collection of items.
/// Can be scrolled left and right.
/// Looped: after last items goes first one.
/// If only single item - user will see endless amounts of this item.
public class InfinityScrollView: UIView {

    private enum Constant {
        static let snapAnimationKey: String = "InfinityScrollView.snapAnimation"
        static let snapAnimationNameValue: String = "InfinityScrollView.snapAnimation.name"
        static let snapAnimationNameKey: String = "InfinityScrollView.snapAnimation.key"
    }

    public weak var dataSource: InfinityScrollViewDataSource?
    public weak var delegate: InfinityScrollViewDelegate?

    /// If `true` content will be decelerated with velocity of drag (after drag is ended)
    ///
    /// Default value is `true`.
    public var isDecelerationEnabled: Bool = true

    /// Deceleration rate.
    /// Use constants from `UIScrollView.DecelerationRate` as guide for possible values.
    ///
    /// Default value is `UIScrollView.DecelerationRate.normal`.
    public var decelerationRate: UIScrollView.DecelerationRate {
        get {
            return internalScrollView.decelerationRate
        }
        set {
            internalScrollView.decelerationRate = newValue
        }
    }

    /// If `true` content will be snapped to nearest item center at drag end. Respects deceleration.
    /// Applies animation if allowed.
    /// Applies deceleration if allowed.
    /// Not recommended if item's width is greater than control's width.
    ///
    /// Default value is `false`.
    public var isSnapEnabled: Bool = false

    /// Animation for snap after dragging ended
    ///
    /// Default value is `SnapAnimation.scrollView`
    public var snapAnimation: SnapAnimation = .scrollView

    /// Behaviour for data source of only one item.
    ///
    /// Default value is `SingleItemBehavior.bounce`.
    public private(set) var singleItemBehavior: SingleItemBehavior = .bounce

    private var internalScrollView: UIScrollView!
    private var contentContainerView: UIView!
    private var touchDownRecognizer: SingleTouchDownGestureRecognizer!
    private var tapRecognizer: UITapGestureRecognizer!

    private var cachedItemWidths: [CGFloat] = []
    private var cachedNumberOfItems: Int = 0
    private var cachedItemsTotalWidth: CGFloat = 0.0

    /// Offset origin.x of view of first item of first iteration from content's centerX.
    ///
    /// -(cachedItems[0].width)/2
    private var cachedZeroItemOffset: CGFloat = 0.0

    /// How much extra space is filled with item's views beyond visible area (internalScrollView.bounds) to the left & right
    ///
    /// = min(bounds.width, 500)
    private var visibleAreaOverhangX: CGFloat = 500.0 // twice frame's width

    /// Views for items that are added to content view.
    /// Index is a tiled (zero-based & pass-through) index: 11 for 9 total items means 3rd item in second iteration.
    private var visibleTileViews: [Int: UIView] = [:]

    /// Minimum of content offset change required to trigger recenter of scrollable content.
    ///
    /// visibleAreaOverhangX / 2
    private var recenterThrottleDistance: CGFloat = 0.0

    private var allowRecenter: Int = 1 // allowed if > 0

    /// The whole width of scrollable area. Should be big enough for user not to "bounce" against it.
    /// Offset will be resetted within it as often as possible, so that user constantly see only ceter-ish section of it.
    ///
    /// 5000.0
    private var scrollableContentWidth: CGFloat = 5000.0

    /// Layout will be skipped, if lastLayoutBoundsSize == bounds.size
    private var lastLayoutBoundsSize: CGSize = .zero

    /// Minimum amount content offset must be changed to trigger views tiling.
    ///
    /// visibleAreaOverhangX / 5
    private var tileThrottleDistance: CGFloat = 0.0

    /// Last time tiling was performed - content offset was here.
    /// Used for throttling of tiling.
    private var tileDoneForContentOffsetX: CGFloat = .infinity

    /// allowed if > 0
    private var allowTiling: Int = 1

    /// Additional offset accumulated due to recentering.
    private var recenteredZeroItemOffset: CGFloat = 0

    /// Will be filled/updated in `scrollViewWillEndDragging(:withVelocity:targetContentOffset:)`.
    /// Used for reporting to delegate and animating deceleration.
    private var decelerationAnimationData: AnimationData?

    /// Animation used for animating deceleration (snap or no snap).
    /// `.none` & `.scrollView` settings do not use this property.
    private var decelerateAnimation: CAAnimation?

    /// Index of the tile under the center
    private var dragStartedTileIndex: Int?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    // MARK: - Events

    public override func layoutSubviews() {
        super.layoutSubviews()

        guard lastLayoutBoundsSize != bounds.size else {
            return
        }

        updateScroll()

        // width-dependent layout
        if lastLayoutBoundsSize.width != bounds.width {
            visibleAreaOverhangX = max(500.0, bounds.width)
            tileThrottleDistance = visibleAreaOverhangX / 5.0
            recenterThrottleDistance = visibleAreaOverhangX / 2.0
            recenterIfNeeded(allowThrottle: false, allowShiftTileViews: false)
            tileItemViewsIfNeeded(allowThrottle: false, targetContentOffsetX: nil)
            setupSingleItemIfNeeded()
        }

        // height-dependent layout
        if lastLayoutBoundsSize.height != bounds.height {
            updateVisibleTileViews(height: bounds.height)
        }

        lastLayoutBoundsSize = bounds.size
    }

    // MARK: - Public

    public func viewForItem(at index: Int) -> UIView? {
        return visibleTileViews[index]
    }

    public func setSelectedIndex(_ selectedIndex: Int, animated: Bool = false) {
        guard visibleTileViews.count > selectedIndex else {
            return
        }
        if let frame = visibleTileViews[selectedIndex]?.frame {
            internalScrollView.setContentOffset(CGPoint(x: frame.midX - (internalScrollView.frame.width / 2), y: 0), animated: animated)
        }
    }

    public func accessibilityScrollForward() {
        guard visibleTileViews.count > 1,
              let currentIndex = indexOfItemAtVisibleCenter()
        else {
            return
        }
        let nextIndex = currentIndex + 1 == visibleTileViews.count ? 0 : currentIndex + 1
        if let frame = visibleTileViews[nextIndex]?.frame {
            internalScrollView.setContentOffset(CGPoint(x: frame.midX - (internalScrollView.frame.width / 2), y: 0), animated: true)
        }
    }

    public func accessibilityScrollBackward() {
        guard visibleTileViews.count > 1,
              let currentIndex = indexOfItemAtVisibleCenter()
        else {
            return
        }
        let previousIndex = currentIndex - 1 == -1 ? visibleTileViews.count - 1 : currentIndex - 1
        if let frame = visibleTileViews[previousIndex]?.frame {
            internalScrollView.setContentOffset(CGPoint(x: frame.midX - (internalScrollView.frame.width / 2), y: 0), animated: true)
        }
    }

    public func reloadData() {
        recreateCacheFromDataSource()
        updateScroll()
        recenterIfNeeded(allowThrottle: false, allowShiftTileViews: false)
        tileItemViewsIfNeeded(allowThrottle: false, targetContentOffsetX: nil)
        setupSingleItemIfNeeded()
    }

    /// The whole width of scrollable area. Should be big enough for user not to "bounce" against it.
    /// Offset will be resetted within it as often as possible, so that user constantly see only ceter-ish section of it.
    ///
    /// Recentering is disabled during animations.
    /// Consider increasing this value if user swipes vilently and device screen is wide.
    /// Suggestion: 10 x Screen.width
    /// It is better to call `reloadData()` if new value is set.
    ///
    /// Default value is 5000.
    public func setScrollableContentWidth(_ newValue: CGFloat) {
        scrollableContentWidth = newValue
        setNeedsLayout()
    }

    /// See singleItemBehavior for description.
    /// Reloading of data is required after changing this setting.
    public func setSingleItemBehavior(_ newValue: SingleItemBehavior) {
        singleItemBehavior = newValue
        internalScrollView.bounces = newValue == .bounce
        internalScrollView.alwaysBounceHorizontal = newValue == .bounce
        setNeedsLayout()
    }

    public override func setNeedsLayout() {
        lastLayoutBoundsSize = .zero
        super.setNeedsLayout()
    }

    /// Index of item, which view is intersecting central line of drawing area.
    ///
    /// - returns: `nil` if there are no items
    public func indexOfItemAtVisibleCenter() -> Int? {
        return nearestVisibleCenterItem(targetOffsetX: internalScrollView.contentOffset.x)?.itemIndex
    }

}

// MARK: - UIScrollViewDelegate

extension InfinityScrollView: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === internalScrollView else {
            return
        }
        tileItemViewsIfNeeded(allowThrottle: true, targetContentOffsetX: nil)
    }

     public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView === internalScrollView else {
            return
        }
        let visibleItem = nearestVisibleCenterItem(targetOffsetX: scrollView.contentOffset.x)
        dragStartedTileIndex = visibleItem?.tileIndex
        if decelerationAnimationData != nil {
            if isDecelerationEnabled {
                if (cachedNumberOfItems > 1) || (singleItemBehavior == .tile) || isSnapEnabled {
                    switch snapAnimation {
                    case .none:
                        // already reported
                        break
                    case .scrollView:
                        // deceleration animation from UIScrollView is used
                        // will report in `scrollViewDidEndDecelerating()`
                        if let itemIndex = visibleItem?.itemIndex {
                            delegate?.infinityScrollView(self, didEndDeceleratingOnItemAtIndex: itemIndex, wasAborted: true)
                        }
                    case .curve, .spring:
                        // will be reported in `animationDidStop(...)`
                        break
                    }
                } else {
                    // special case for single item: non-scrollView animation do not work
                    // : deceleration animation from UIScrollView is used
                    // : will report in `scrollViewDidEndDecelerating()`
                    if let itemIndex = visibleItem?.itemIndex {
                        delegate?.infinityScrollView(self, didEndDeceleratingOnItemAtIndex: itemIndex, wasAborted: true)
                    }
                }
            } else {
                // already reported
            }
        } else {
            // already reported
        }
        stopSnapAnimation()
        decelerationAnimationData = nil // beginning of next drag cycle
        recenterIfNeeded(allowThrottle: true, allowShiftTileViews: true)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === internalScrollView else {
            return
        }
        if let decelerationData = decelerationAnimationData {
            if isDecelerationEnabled {
                if (cachedNumberOfItems > 1) || (singleItemBehavior == .tile) || isSnapEnabled {
                    switch snapAnimation {
                    case .none:
                        // no animation
                        internalScrollView.bounds.origin.x = decelerationData.projectedContentOffsetX
                        // report
                        delegate?.infinityScrollView(self,
                                                     didEndDeceleratingOnItemAtIndex: decelerationData.nearestItemData.itemIndex,
                                                     wasAborted: false)
                    case .scrollView:
                        // deceleration animation from UIScrollView is used
                        // will report in `scrollViewDidEndDecelerating(...)` or `scrollViewWillBeginDragging(...)`
                        break
                    case .curve, .spring:
                        startSnapAnimation(initialVelocityX: decelerationData.initialVelocityX,
                                           targetContentOffset: CGPoint(x: decelerationData.projectedContentOffsetX, y: 0))
                    }
                } else {
                    // fallback to 'scrollView' behaviour - other animations make no sense and do not work
                    // : deceleration animation from UIScrollView is used
                    // : will report in `scrollViewDidEndDecelerating(...)` or `scrollViewWillBeginDragging(...)`
                }
            } else {
                delegate?.infinityScrollView(self, didEndDeceleratingOnItemAtIndex: decelerationData.nearestItemData.itemIndex, wasAborted: false)
            }
        } else {
            // there are no items - nothing to work with
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === internalScrollView else {
            return
        }
        if decelerationAnimationData != nil {
            if isDecelerationEnabled {
                if (cachedNumberOfItems > 1) || (singleItemBehavior == .tile) || isSnapEnabled {
                    switch snapAnimation {
                    case .none:
                        // already reported
                        break
                    case .scrollView:
                        if let itemIndex = nearestVisibleCenterItem(targetOffsetX: scrollView.contentOffset.x)?.itemIndex {
                            delegate?.infinityScrollView(self, didEndDeceleratingOnItemAtIndex: itemIndex, wasAborted: false)
                        }
                        decelerationAnimationData = nil
                    case .curve, .spring:
                        // will be reported in `animationDidStop(...)`
                        break
                    }
                } else {
                    // special case for single item behaviour: non-scrollView animations do not work
                    if let itemIndex = nearestVisibleCenterItem(targetOffsetX: scrollView.contentOffset.x)?.itemIndex {
                        // in case of bounce: scrollViewDidEndDecelerating will be called before scrollViewWillBeginDragging
                        // so, if scrollView.isTracking -> deceleration (bounce) was aborted
                        delegate?.infinityScrollView(self, didEndDeceleratingOnItemAtIndex: itemIndex, wasAborted: scrollView.isTracking)
                    }
                    decelerationAnimationData = nil
                }
            } else {
                // already reported
            }
        } else {
            // already reported
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === internalScrollView else {
            return
        }
        var projectedContentOffsetX = scrollView.contentOffset.x
        if isDecelerationEnabled {
            projectedContentOffsetX = DecelerationHelper.project(value: scrollView.contentOffset.x,
                                                                 initialVelocity: velocity.x,
                                                                 decelerationRate: scrollView.decelerationRate.rawValue)
            tileItemViewsIfNeeded(allowThrottle: false, targetContentOffsetX: projectedContentOffsetX)
        }

        if let nearestItemData = nearestVisibleCenterItem(targetOffsetX: projectedContentOffsetX) {
            if let startIndex = dragStartedTileIndex {
                let direction = swipeDirection(startIndex: startIndex, endIndex: nearestItemData.tileIndex)
                delegate?.infinityScrollView(self, willEndSwipeOnItemAtIndex: nearestItemData.itemIndex, swipeDirection: direction)
            }
            if isSnapEnabled {
                projectedContentOffsetX = nearestItemData.anchorOffsetX
            }
            decelerationAnimationData = AnimationData(projectedContentOffsetX: projectedContentOffsetX,
                                                      nearestItemData: nearestItemData,
                                                      initialVelocityX: velocity.x)
            if (cachedNumberOfItems > 1) || (singleItemBehavior == .tile) || isSnapEnabled {
                switch snapAnimation {
                case .none:
                    targetContentOffset.pointee = scrollView.contentOffset // stop system animation
                case .scrollView:
                    targetContentOffset.pointee = CGPoint(x: projectedContentOffsetX, y: 0)
                case .curve, .spring:
                    targetContentOffset.pointee = scrollView.contentOffset // stop system animation
                    allowTiling -= 1
                    allowRecenter -= 1
                }
            } else {
                // without snap non-scrollview animations make no sense for non-tiled single item -> fallback to scrollView
                targetContentOffset.pointee = CGPoint(x: projectedContentOffsetX, y: 0)
            }
        }
    }

}

// MARK: - CAAnimationDelegate

extension InfinityScrollView: CAAnimationDelegate {

    public func animationDidStop(_ anim: CAAnimation, finished finishedFlag: Bool) {
        if let animationName = anim.value(forKey: Constant.snapAnimationNameKey) as? String,
            animationName == Constant.snapAnimationNameValue {
            allowRecenter += 1
            allowTiling += 1
            decelerateAnimation?.delegate = nil
            decelerateAnimation = nil
            if isDecelerationEnabled {
                switch snapAnimation {
                case .none:
                    // already reported
                    break
                case .scrollView:
                    // will be reported in `scrollViewDidEndDecelerating(...)` or `scrollViewDidEndDragging(...)`
                    break
                case .curve, .spring:
                    if let presentationLayer = internalScrollView.layer.presentation(),
                        let nearestItem = nearestVisibleCenterItem(targetOffsetX: presentationLayer.bounds.origin.x) {
                        delegate?.infinityScrollView(self,
                                                     didEndDeceleratingOnItemAtIndex: nearestItem.itemIndex,
                                                     wasAborted: !finishedFlag)
                    } else {
                        // nothing to report about
                    }
                }
            } else {
                // already reported
            }
        }
    }

}

// MARK: - UIGestureRecognizerDelegate

extension InfinityScrollView: UIGestureRecognizerDelegate {

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        switch gestureRecognizer {
        case touchDownRecognizer:
            return internalScrollView.layer.animation(forKey: Constant.snapAnimationKey) != nil
        case tapRecognizer:
            return (internalScrollView.layer.animation(forKey: Constant.snapAnimationKey) == nil) && !internalScrollView.isDecelerating
        default:
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        switch gestureRecognizer {
        case touchDownRecognizer,
             tapRecognizer:
            return true
        default:
            return false
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer === tapRecognizer) && (otherGestureRecognizer === touchDownRecognizer) {
            return true
        } else {
            return false
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer === touchDownRecognizer) && (otherGestureRecognizer === touchDownRecognizer) {
            return true
        } else {
            return false
        }
    }

}

// MARK: - Private

private extension InfinityScrollView {

    private func commonInit() {
        let scrollView = UIScrollView(frame: bounds)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = UIScrollView.DecelerationRate.normal
        scrollView.scrollsToTop = false
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.clear
        scrollView.contentSize = CGSize(width: scrollableContentWidth, height: bounds.height)
        scrollView.translatesAutoresizingMaskIntoConstraints = true // manual layout by frame
        addSubview(scrollView)
        internalScrollView = scrollView

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: scrollableContentWidth, height: bounds.height))
        containerView.backgroundColor = UIColor.clear
        containerView.translatesAutoresizingMaskIntoConstraints = true // manual layout by frame
        scrollView.addSubview(containerView)
        contentContainerView = containerView

        let localTouchDownRecognizer = SingleTouchDownGestureRecognizer(target: self, action: #selector(handleSingleTouchDownGestureRecognized(_:)))
        localTouchDownRecognizer.delegate = self
        internalScrollView.addGestureRecognizer(localTouchDownRecognizer)
        touchDownRecognizer = localTouchDownRecognizer

        let localTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognized(_:)))
        localTapRecognizer.delegate = self
        addGestureRecognizer(localTapRecognizer)
        tapRecognizer = localTapRecognizer
    }

    private func recreateCacheFromDataSource() {
        visibleTileViews.forEach({ $0.value.removeFromSuperview() })
        visibleTileViews.removeAll()
        tileDoneForContentOffsetX = .infinity
        cachedNumberOfItems = 0
        cachedItemWidths.removeAll()
        cachedItemsTotalWidth = 0
        cachedZeroItemOffset = 0
        recenteredZeroItemOffset = 0
        guard let strongDataSource = dataSource else {
            return
        }
        cachedNumberOfItems = strongDataSource.infinityScrollViewNumberOfItems(self)
        assert(cachedNumberOfItems >= 0, "number of items can't be negative")
        guard cachedNumberOfItems > 0 else {
            return
        }
        for itemIndex in 0..<cachedNumberOfItems {
            let itemWidth = strongDataSource.infinityScrollView(self, widthForItemAtIndex: itemIndex)
            cachedItemWidths.append(itemWidth)
            cachedItemsTotalWidth += itemWidth
        }
        cachedZeroItemOffset = -cachedItemWidths[0] / 2.0
    }

    /// Tile views for items to fill visible area.
    /// Fillable area extended by `visibleAreaOverhangX` left and right.
    ///
    /// - parameter allowThrottle: if `true` tiling will be skipped if change to contentOffset was not significant enough (`tileThrottleDistance`)
    ///                 since last tiling moment.
    /// - parameter targetContentOffsetX: if `nil` current content offset is taken for visible area.
    ///                 Otherwise visible area expanded to include `targetContentOffsetX`.
    private func tileItemViewsIfNeeded(allowThrottle: Bool, targetContentOffsetX: CGFloat?) {
        guard allowTiling > 0,
            cachedNumberOfItems > 0,
            (cachedNumberOfItems > 1 || singleItemBehavior == .tile),
            let strongDataSource = dataSource else {
            return
        }

        let contentOffsetDistance = abs(tileDoneForContentOffsetX - internalScrollView.contentOffset.x)
        guard !allowThrottle || contentOffsetDistance > tileThrottleDistance else {
            return
        }

        let visibleBounds = internalScrollView.bounds
        let minVisibleX: CGFloat
        let maxVisibleX: CGFloat
        if let targetX = targetContentOffsetX {
            minVisibleX = min(visibleBounds.minX, targetX) - visibleAreaOverhangX
            maxVisibleX = max(visibleBounds.maxX, targetX) + visibleAreaOverhangX
        } else {
            minVisibleX = visibleBounds.minX - visibleAreaOverhangX
            maxVisibleX = visibleBounds.maxX + visibleAreaOverhangX
        }

        // remove existing tiles, that are no longer visible
        for (index, tileView) in visibleTileViews {
            if (tileView.frame.minX > maxVisibleX) || (tileView.frame.maxX < minVisibleX) {
                visibleTileViews.removeValue(forKey: index)
                tileView.removeFromSuperview()
            }
        }

        // prepare for adding new tiles
        let zeroItemStartX = scrollableContentWidth / 2.0 + cachedZeroItemOffset + recenteredZeroItemOffset
        let iterationMultiplier = floor((minVisibleX - zeroItemStartX) / cachedItemsTotalWidth)
        let tileStartX = zeroItemStartX + iterationMultiplier * cachedItemsTotalWidth

        // skip non-visible tiles (to the left of minVisibleX)
        var currentTileX = tileStartX
        var currentTileIndex: Int = 0 + Int(iterationMultiplier) * cachedNumberOfItems
        var currentItemWidth = cachedItemWidths[itemIndex(tileIndex: currentTileIndex)]
        var currentTileMaxX = currentTileX + currentItemWidth
        while currentTileMaxX < minVisibleX {
            currentTileIndex += 1
            currentItemWidth = cachedItemWidths[itemIndex(tileIndex: currentTileIndex)]
            currentTileX = currentTileMaxX
            currentTileMaxX += currentItemWidth
        }

        // add new tiles
        let itemHeight = visibleBounds.height
        while currentTileX < maxVisibleX {
            let currentItemIndex = itemIndex(tileIndex: currentTileIndex)
            currentItemWidth = cachedItemWidths[currentItemIndex]
            if visibleTileViews[currentTileIndex] == nil {
                let newTileFrame = CGRect(x: currentTileX, y: 0, width: currentItemWidth, height: itemHeight)
                let newTileView = strongDataSource.infinityScrollView(self, viewForItemAtIndex: currentItemIndex, size: newTileFrame.size)
                newTileView.frame = newTileFrame
                contentContainerView.addSubview(newTileView)
                visibleTileViews[currentTileIndex] = newTileView
            }
            currentTileX += currentItemWidth
            currentTileIndex += 1
        }

        tileDoneForContentOffsetX = internalScrollView.contentOffset.x
    }

    private func itemIndex(tileIndex: Int) -> Int {
        var result = tileIndex % cachedNumberOfItems
        if result < 0 {
            result += cachedNumberOfItems
        }
        return result
    }

    /// Move content so that center of content align with visual center of InfinityScrollView.
    /// - parameter allowThrottle: if true - recentering will be skipped, if since last time content offset was changed too little.
    /// - parameter allowShiftTileViews: if true - tile views will be shifted in the opposite of 'recenter' direction to keep them visually in place.
    private func recenterIfNeeded(allowThrottle: Bool, allowShiftTileViews: Bool) {
        guard allowRecenter > 0, (cachedNumberOfItems > 1 || singleItemBehavior == .tile) else {
            return
        }

        let currentOffsetX = internalScrollView.contentOffset.x
        let centerOffsetX = (internalScrollView.contentSize.width - internalScrollView.bounds.size.width) / 2.0
        let shiftX = centerOffsetX - currentOffsetX
        if !allowThrottle || abs(shiftX) > recenterThrottleDistance {
            allowTiling -= 1
            internalScrollView.contentOffset = CGPoint(x: centerOffsetX, y: 0)
            tileDoneForContentOffsetX += shiftX // sync throttling for tiling
            if allowShiftTileViews {
                for (_, tileView) in visibleTileViews {
                    var tileFrame = tileView.frame
                    tileFrame.origin.x += shiftX
                    tileView.frame = tileFrame
                }
                recenteredZeroItemOffset += shiftX
            }
            allowTiling += 1
        }
    }

    private func updateVisibleTileViews(height newHeight: CGFloat) {
        visibleTileViews.forEach({ (_, tileView) in
            tileView.frame.size.height = newHeight
        })
    }

    /// Update scrollable area
    private func updateScroll() {
        internalScrollView.frame = bounds
        let contentWidth: CGFloat
        if cachedNumberOfItems == 1, singleItemBehavior != .tile {
            contentWidth = max(bounds.width, cachedItemsTotalWidth)
        } else {
            contentWidth = scrollableContentWidth
        }
        internalScrollView.contentSize = CGSize(width: contentWidth, height: bounds.height)
        contentContainerView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: bounds.height)
    }

    /// Special case for single item in data source when tiling is not allowed
    private func setupSingleItemIfNeeded() {
        guard cachedNumberOfItems == 1, singleItemBehavior != .tile, let strongDataSource = dataSource else {
            return
        }
        // add single tile
        let contentSize = contentContainerView.bounds.size
        let itemIndex: Int = 0
        let itemWidth = cachedItemWidths[itemIndex]
        let tileView: UIView
        if let oldTileView = visibleTileViews[itemIndex] {
            tileView = oldTileView
        } else {
            let newTileFrame = CGRect(x: 0, y: 0, width: itemWidth, height: contentSize.height)
            let newTileView = strongDataSource.infinityScrollView(self, viewForItemAtIndex: itemIndex, size: newTileFrame.size)
            newTileView.frame = newTileFrame
            contentContainerView.addSubview(newTileView)
            visibleTileViews[itemIndex] = newTileView
            tileView = newTileView
        }
        tileView.frame = CGRect(x: (contentSize.width - itemWidth) / 2.0,
                                y: 0,
                                width: itemWidth,
                                height: contentSize.height)
    }

    /// this function assumes, that views for items was already tiled in advance.
    ///
    /// - parameter targetOffsetX: offset for internal scroll view to look nearst item around.
    /// - returns:
    ///     `nil` if there are no items.
    ///     Descriptive data about nearest item/tile.
    ///     We are aiming to place center of item to the center of visible area.
    private func nearestVisibleCenterItem(targetOffsetX: CGFloat) -> NearestVisibleCenterItemData? {
        let screenHalfWidth = bounds.width / 2.0
        let targetCenterX = targetOffsetX + screenHalfWidth
        var nearestTile: Dictionary<Int, UIView>.Element?
        var nearestDistance: CGFloat = .infinity
        for tile in visibleTileViews {
            let distance = abs(tile.value.frame.origin.x + (tile.value.frame.size.width / 2.0) - targetCenterX)
            if distance < nearestDistance {
                nearestTile = tile
                nearestDistance = distance
            }
        }

        guard let foundElement = nearestTile else {
            return nil
        }

        let tileCenterX = foundElement.value.frame.origin.x + foundElement.value.frame.size.width / 2.0
        return NearestVisibleCenterItemData(anchorOffsetX: tileCenterX - screenHalfWidth ,
                                            tileCenterX: tileCenterX,
                                            itemIndex: itemIndex(tileIndex: foundElement.key),
                                            tileIndex: foundElement.key)
    }

    private func startSnapAnimation(initialVelocityX: CGFloat, targetContentOffset: CGPoint) {
        stopSnapAnimation()

        let fromBounds = internalScrollView.bounds
        let toBounds = CGRect(x: targetContentOffset.x, y: targetContentOffset.y, width: fromBounds.width, height: fromBounds.height)

        switch snapAnimation {
        case .none,
             .scrollView:
            // should not be here - these two settings handled by `scrollViewWillEndDragging(:withVelocity:targetContentOffset:)`
            stopSnapAnimation()

        case .curve(let duration, let name):
            let animation = CABasicAnimation(keyPath: "bounds")
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: name)
            animation.fromValue = NSValue(cgRect: fromBounds)
            animation.toValue = NSValue(cgRect: toBounds)
            animation.isRemovedOnCompletion = true
            animation.delegate = self
            animation.setValue(Constant.snapAnimationNameValue, forKey: Constant.snapAnimationNameKey)
            decelerateAnimation = animation
            internalScrollView.layer.bounds = toBounds
            internalScrollView.layer.add(animation, forKey: Constant.snapAnimationKey)

        case .spring(let mass, let stiffness, let damping):
            let animation = CASpringAnimation(keyPath: "bounds")
            animation.mass = mass
            animation.stiffness = stiffness
            animation.damping = damping
            animation.initialVelocity = abs(initialVelocityX)
            animation.fromValue = NSValue(cgRect: fromBounds)
            animation.toValue = NSValue(cgRect: toBounds)
            animation.duration = animation.settlingDuration
            animation.isRemovedOnCompletion = true
            animation.delegate = self
            animation.setValue(Constant.snapAnimationNameValue, forKey: Constant.snapAnimationNameKey)
            decelerateAnimation = animation
            internalScrollView.layer.bounds = toBounds
            internalScrollView.layer.add(animation, forKey: Constant.snapAnimationKey)
        }
    }

    private func stopSnapAnimation() {
        guard internalScrollView.layer.animation(forKey: Constant.snapAnimationKey) != nil else {
            return
        }
        if let presentationLayer = internalScrollView.layer.presentation() {
            internalScrollView.layer.bounds = presentationLayer.bounds
            // NOTE: There is a slight but noticeable glitch:
            //          - next frame is rendered as if animation is still going
            //          - frame after next is rendered with "stopped" bounds
        }
        internalScrollView.layer.removeAnimation(forKey: Constant.snapAnimationKey)
    }

    private func swipeDirection(startIndex: Int, endIndex: Int) -> SwipeDirection {
        if startIndex == endIndex {
            return .none
        } else if startIndex > endIndex {
            return .left
        } else {
            return .right
        }
    }

    @objc private func handleSingleTouchDownGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        stopSnapAnimation()
    }

    @objc private func handleTapGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.location(in: internalScrollView)
        // not using `nearestVisibleCenterItem()` here: that function is heavier and adjusts for center of visible area
        var nearestTile: Dictionary<Int, UIView>.Element?
        var nearestDistance: CGFloat = .infinity
        for tile in visibleTileViews {
            let distance = abs(tile.value.frame.origin.x + (tile.value.frame.size.width / 2.0) - point.x)
            if distance < nearestDistance {
                nearestTile = tile
                nearestDistance = distance
            }
        }
        guard let foundElement = nearestTile else {
            return
        }
        let index = itemIndex(tileIndex: foundElement.key)
        delegate?.infinityScrollView(self, didSelectItemAtIndex: index)
    }

}
