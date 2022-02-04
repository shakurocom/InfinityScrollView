//
//  Copyright © 2019 Shakuro. All rights reserved.
//

import UIKit

extension UIColor {

    /// Creates UIColor instance from random components in range
    ///
    /// - Parameters:
    ///   - redRange: The range for red color component max range is 0..255
    ///   - greenRange: The range for green color component max range is 0..255
    ///   - blueRange: The range for blue color component max range is 0..255
    ///   - alpha: The alpha value of color
    /// - Returns: A random color
    public static func random(redRange: ClosedRange<Int> = 0...255,
                              greenRange: ClosedRange<Int> = 0...255,
                              blueRange: ClosedRange<Int> = 0...255,
                              alpha: CGFloat = 1.0) -> UIColor {
        let redValue = CGFloat(Int.random(in: redRange)) / 255.0
        let greenValue = CGFloat(Int.random(in: greenRange)) / 255.0
        let blueValue = CGFloat(Int.random(in: blueRange)) / 255.0
        return UIColor(red: redValue,
                       green: greenValue,
                       blue: blueValue,
                       alpha: alpha)
    }

    /// Init UIColor with decimal representation
    ///
    /// - parameter rgbDecimalColor: A decimal representation color: 0xRRGGBB (first byte not used)
    public convenience init(rgbDecimalColor: UInt32) {
        let mask = 0x000000FF
        let rComponent: Int = Int(rgbDecimalColor >> 16) & mask
        let gComponent: Int = Int(rgbDecimalColor >> 8) & mask
        let bComponent: Int = Int(rgbDecimalColor) & mask

        let red: CGFloat = CGFloat(rComponent) / 255.0
        let green: CGFloat = CGFloat(gComponent) / 255.0
        let blue: CGFloat = CGFloat(bComponent) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    /// Init UIColor with hexadecimal representation.
    ///
    /// - Parameter hex: A hexadecimal color string
    ///
    /// - returns: `nil` if string do not contain hex value.
    public convenience init?(hex: String) {
        let validateHex: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner: Scanner = Scanner(string: validateHex)

        if validateHex.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        guard scanner.scanHexInt32(&color) else {
            return nil
        }
        self.init(rgbDecimalColor: color)
    }

    /// Init UIColor with channels as UInt8.
    ///
    /// - parameter red: red channel
    /// - parameter green: green channel
    /// - parameter blue: blue channel
    /// - parameter floatAlpha: alpha channel. Float. Default value is `1.0`.
    public convenience init(uint8Red red: UInt8, green: UInt8, blue: UInt8, floatAlpha: CGFloat = 1.0) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: floatAlpha)
    }

    /// Generates image from color
    ///
    /// - Parameters:
    ///   - destinationSize: The size of result image
    ///   - scale: UIImage.scale, Pass 0 for auto selection
    ///   - opaque: If true result image will be opaque
    /// - Returns: UIImage instance or nil
    public func generateImage(destinationSize: CGSize = CGSize(width: 1.0, height: 1.0),
                              scale: CGFloat = 0,
                              opaque: Bool = false) -> UIImage? {
        guard !destinationSize.equalTo(CGSize.zero) else {
            return nil
        }
        defer {
            UIGraphicsEndImageContext()
        }
        let drawRect = CGRect(origin: CGPoint(x: 0, y: 0), size: destinationSize)
        UIGraphicsBeginImageContextWithOptions(drawRect.size, opaque, scale)
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        currentContext.setFillColor(cgColor)
        currentContext.fill(drawRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

}
