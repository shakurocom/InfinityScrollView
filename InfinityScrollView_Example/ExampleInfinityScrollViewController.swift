//
// Copyright (c) 2020 Shakuro (https://shakuro.com/)
//

import InfinityScrollView_Framework
import Shakuro_CommonTypes
import UIKit

class ExampleInfinityScrollViewController: UIViewController {

    @IBOutlet private var infinityScrollView: InfinityScrollView!
    @IBOutlet private var numberOfItemsTextField: UITextField!
    @IBOutlet private var numberOfItemsSegmentedControl: UISegmentedControl!
    @IBOutlet private var useConstantItemWidthSwitch: UISwitch!
    @IBOutlet private var constantItemWidthSwitch: UISwitch!
    @IBOutlet private var showItemsBackgroundSwitch: UISwitch!
    @IBOutlet private var showVisualCenterMarkerSwitch: UISwitch!
    @IBOutlet private var visualCenterMarkerView: UIView!
    @IBOutlet private var showContentCenterMarkerSwitch: UISwitch!
    @IBOutlet private var useHalfHeightSwitch: UISwitch!
    @IBOutlet private var isDecelerationEnabledSwitch: UISwitch!
    @IBOutlet private var useFastDecelerationRateSwitch: UISwitch!
    @IBOutlet private var isSnapEnabledSwitch: UISwitch!
    @IBOutlet private var snapAnimationSegmentedControl1: UISegmentedControl!
    @IBOutlet private var snapAnimationSegmentedControl2: UISegmentedControl!
    @IBOutlet private var singleItemBehaviourSegmentedControl: UISegmentedControl!

    private var contentCenterMarkerView: UIView!

    @IBOutlet private var infinityScrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var infinityScrollViewHeightConstraint: NSLayoutConstraint!

    private var keyboardHandler: KeyboardHandler?
    private var numberOfItems: Int = 10

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        infinityScrollView.dataSource = self
        infinityScrollView.delegate = self
        infinityScrollViewHeightConstraint.constant = 200
        numberOfItemsTextField.text = "\(numberOfItems)"
        numberOfItemsTextField.delegate = self
        numberOfItemsSegmentedControl.selectedSegmentIndex = 3
        useConstantItemWidthSwitch.isOn = true
        constantItemWidthSwitch.isOn = false
        showItemsBackgroundSwitch.isOn = false
        showVisualCenterMarkerSwitch.isOn = true
        visualCenterMarkerView.backgroundColor = UIColor.red
        showContentCenterMarkerSwitch.isOn = true
        useHalfHeightSwitch.isOn = false
        isDecelerationEnabledSwitch.isOn = infinityScrollView.isDecelerationEnabled
        useFastDecelerationRateSwitch.isOn = infinityScrollView.decelerationRate == .fast
        isSnapEnabledSwitch.isOn = infinityScrollView.isSnapEnabled
        snapAnimationSegmentedControl1.selectedSegmentIndex = 1
        snapAnimationSegmentedControl2.selectedSegmentIndex = -1
        infinityScrollView.snapAnimation = .scrollView
        singleItemBehaviourSegmentedControl.selectedSegmentIndex = 0
        infinityScrollView.setSingleItemBehavior(.tile)
        // a little bit of hacks (do not do this, kids)
        if let contentView = infinityScrollView.subviews.first(where: { $0 is UIScrollView })?.subviews.first {
            contentCenterMarkerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: infinityScrollView.frame.height))
            contentCenterMarkerView.backgroundColor = UIColor.green
            contentCenterMarkerView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(contentCenterMarkerView)
            contentCenterMarkerView.widthAnchor.constraint(equalToConstant: 1).isActive = true
            contentCenterMarkerView.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
            contentCenterMarkerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
            contentCenterMarkerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        }

        keyboardHandler = KeyboardHandler(enableCurveHack: false, heightDidChange: { [weak self] (change: KeyboardHandler.KeyboardChange) in
            guard let strongSelf = self else {
                return
            }
            UIView.animate(
                withDuration: change.animationDuration,
                delay: 0.0,
                animations: {
                    UIView.setAnimationCurve(change.animationCurve)
                    strongSelf.infinityScrollViewBottomConstraint.constant = change.newHeight
                    strongSelf.view.layoutIfNeeded()
            },
                completion: nil)
        })
        infinityScrollView.reloadData()
    }

    // MARK: - Events

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardHandler?.isActive = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardHandler?.isActive = false
    }

    // MARK: - Interface callbacks

    @IBAction private func numberOfItemsSegmentedControlValueChanged() {
        let segmentTitle = numberOfItemsSegmentedControl.titleForSegment(at: numberOfItemsSegmentedControl.selectedSegmentIndex)
        if let realTitle = segmentTitle, let newNumber = Int(realTitle) {
            numberOfItems = newNumber
            numberOfItemsTextField.text = "\(numberOfItems)"
            infinityScrollView.reloadData()
        }
    }

    @IBAction private func useConstantItemWidthSwitchValueChanged() {
        infinityScrollView.reloadData()
    }

    @IBAction private func constantItemWidthSwitchValueChanged() {
        infinityScrollView.reloadData()
    }

    @IBAction private func showItemsBackgroundSwitchValueChanged() {
        infinityScrollView.reloadData()
    }

    @IBAction private func showVisualCenterMarkerSwitchValueChanged() {
        visualCenterMarkerView.isHidden = !showVisualCenterMarkerSwitch.isOn
    }

    @IBAction private func showContentCenterMarkerSwitchValueChanged() {
        contentCenterMarkerView.isHidden = !showContentCenterMarkerSwitch.isOn
    }

    @IBAction private func useHalfHeightSwitchValueChanged() {
        infinityScrollViewHeightConstraint.constant = useHalfHeightSwitch.isOn ? 100 : 200
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: [.beginFromCurrentState, .allowUserInteraction],
                       animations: { self.infinityScrollView.superview?.layoutIfNeeded() },
                       completion: nil)
    }

    @IBAction private func isDecelerationEnabledSwitchValueChanged() {
        infinityScrollView.isDecelerationEnabled = isDecelerationEnabledSwitch.isOn
    }

    @IBAction private func useFastDecelerationRateSwitchValueChanged() {
        infinityScrollView.decelerationRate = useFastDecelerationRateSwitch.isOn ? .fast : .normal
    }

    @IBAction private func isSnapEnabledSwitchValueChanged() {
        infinityScrollView.isSnapEnabled = isSnapEnabledSwitch.isOn
    }

    @IBAction private func snapAnimationSegmentedControl1ValueChanged() {
        switch snapAnimationSegmentedControl1.selectedSegmentIndex {
        case 0:
            infinityScrollView.snapAnimation = .none
        case 1:
            infinityScrollView.snapAnimation = .scrollView
        case 2:
            infinityScrollView.snapAnimation = .defaultSpring
        case 3:
            infinityScrollView.snapAnimation = .curve(duration: 0.4, name: .linear)
        case 4:
            infinityScrollView.snapAnimation = .curve(duration: 0.4, name: .easeIn)
        default: break
        }
        snapAnimationSegmentedControl2.selectedSegmentIndex = -1
    }

    @IBAction private func snapAnimationSegmentedControl2ValueChanged() {
        switch snapAnimationSegmentedControl2.selectedSegmentIndex {
        case 0:
            infinityScrollView.snapAnimation = .curve(duration: 0.4, name: .easeOut)
        case 1:
            infinityScrollView.snapAnimation = .curve(duration: 0.4, name: .easeInEaseOut)
        case 2:
            infinityScrollView.snapAnimation = .curve(duration: 0.4, name: .default)
        case 3:
            infinityScrollView.snapAnimation = .spring(mass: 20, stiffness: 0.5, damping: 1)
        default: break
        }
        snapAnimationSegmentedControl1.selectedSegmentIndex = -1
    }

    @IBAction private func singleItemBehaviourSegmentedControlValueChanged() {
        switch singleItemBehaviourSegmentedControl.selectedSegmentIndex {
        case 0:
            infinityScrollView.setSingleItemBehavior(InfinityScrollView.SingleItemBehavior.tile)
        case 1:
            infinityScrollView.setSingleItemBehavior(InfinityScrollView.SingleItemBehavior.bounce)
        case 2:
            infinityScrollView.setSingleItemBehavior(InfinityScrollView.SingleItemBehavior.noBounce)
        default: break
        }
        infinityScrollView.reloadData()
    }

}

// MARK: - UITextFieldDelegate

extension ExampleInfinityScrollViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField === numberOfItemsTextField {
            var newNumber: Int = 0
            if let text = textField.text {
                newNumber = Int(text) ?? 0
            }
            numberOfItems = newNumber
            numberOfItemsTextField.text = "\(numberOfItems)"
            numberOfItemsSegmentedControl.selectedSegmentIndex = 3
            infinityScrollView.reloadData()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

}

// MARK: - InfinityScrollViewDataSource

extension ExampleInfinityScrollViewController: InfinityScrollViewDataSource {

    func infinityScrollViewNumberOfItems(_ infinityScrollView: InfinityScrollView) -> Int {
        return numberOfItems
    }

    func infinityScrollView(_ infinityScrollView: InfinityScrollView, widthForItemAtIndex index: Int) -> CGFloat {
        if useConstantItemWidthSwitch.isOn {
            return constantItemWidthSwitch.isOn ? 40.0 : 200.0
        } else {
            return CGFloat.random(in: 50.0...400.0)
        }
    }

    func infinityScrollView(_ infinityScrollView: InfinityScrollView, viewForItemAtIndex index: Int, size: CGSize) -> UIView {
        let itemColors = ItemColors(itemIndex: index)
        let itemView = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        itemView.backgroundColor = showItemsBackgroundSwitch.isOn ? itemColors.background : UIColor.clear
        let foregroundView = UIView(frame: itemView.bounds.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)))
        foregroundView.layer.masksToBounds = true
        foregroundView.layer.cornerRadius = 4.0
        foregroundView.backgroundColor = itemColors.foreground
        foregroundView.translatesAutoresizingMaskIntoConstraints = true
        foregroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        itemView.addSubview(foregroundView)
        let label = UILabel(frame: foregroundView.bounds.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)))
        label.text = "\(index)"
        label.textColor = itemColors.isForegroundDark ? UIColor.white : UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = true
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        foregroundView.addSubview(label)
        return itemView
    }

}

// MARK: - InfinityScrollViewDelegate

extension ExampleInfinityScrollViewController: InfinityScrollViewDelegate {

    func infinityScrollView(_ infinityScrollView: InfinityScrollView,
                            willEndSwipeOnItemAtIndex itemIndex: Int,
                            swipeDirection: InfinityScrollView.SwipeDirection) {
        print("delegate: willEndSwipeOnItemAtIndex: \(itemIndex)  swipeDirection: \(swipeDirection)")
    }

    func infinityScrollView(_ infinityScrollView: InfinityScrollView, didEndDeceleratingOnItemAtIndex itemIndex: Int, wasAborted: Bool) {
        print("delegate: didEndDeceleratingOnItemAtIndex: \(itemIndex), wasAborted: \(wasAborted)")
    }

    func infinityScrollView(_ infinityScrollView: InfinityScrollView, didSelectItemAtIndex itemIndex: Int) {
        print("delegate: didSelectItemAtIndex: \(itemIndex)")
    }

}

// MARK: - ItemColors

extension ExampleInfinityScrollViewController {

    private struct ItemColors {

        internal let background: UIColor
        internal let foreground: UIColor
        internal let isForegroundDark: Bool

        internal init(itemIndex: Int) {
            let step: UInt32 = 0x11 * 40 // 0x11
            let maxIndex: UInt32 = 0xFFFFFF / step / 2 - 1
            let index = UInt32(itemIndex) % maxIndex
            background = UIColor(rgbDecimalColor: (index * 2 + 0) * step)
            foreground = UIColor(rgbDecimalColor: (index * 2 + 1) * step)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            foreground.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            let brightness = (red / 255.0) * 0.3 + (green / 255.0) * 0.59 + (blue / 255.0) * 0.11
            isForegroundDark = brightness < 0.3
        }

    }

}
