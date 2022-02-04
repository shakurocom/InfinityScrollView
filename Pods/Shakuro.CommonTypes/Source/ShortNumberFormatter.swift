//
//  Copyright © 2019 Shakuro. All rights reserved.
//

import Foundation

public final class ShortNumberFormatter {

    private enum Constant {
        static let suffixes: [String] = [ "", "k", "M", "G", "T", "P", "E" ]
        static let step: Double = 1000
        static let digitsInStep: Int = 3
    }

    let numberFormatter: NumberFormatter

    ///
    /** - Parameter numberFormatter: NumberFormatter instance or nil,
     in case of nil default number formatter (maximumFractionDigits = 2, minimumFractionDigits = 0, roundingMode = .down ) will be created atumatically
     */
    public init(numberFormatter: NumberFormatter? = nil) {
        if let actualFormatter = numberFormatter {
            self.numberFormatter = actualFormatter
        } else {
            let formatter: NumberFormatter = NumberFormatter()
            formatter.locale = Locale.current
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            formatter.roundingMode = .down
            self.numberFormatter = formatter
        }
    }

    /// Transforms double value to string with SI decimal prefix, 1000 -> 1k
    ///
    /// - Parameter value: The value to transform
    /// - Returns: A formatted string
    public func string(for value: Double) -> String {
        let absValue: Double = abs(value)
        let suffixes = Constant.suffixes
        let suffixIndex: Int
        let shortValue: Double
        if absValue < Constant.step {
            suffixIndex = 0
            shortValue = value
        } else {
            let digitCount: Double = log10(absValue)
            if digitCount.isFinite {
                let maxIndex = suffixes.count - 1
                let maxDigitCount = Double(Constant.digitsInStep * maxIndex)
                suffixIndex = digitCount < maxDigitCount ? Int(digitCount / Double(Constant.digitsInStep)) : maxIndex
                shortValue = value / pow(Constant.step, Double(suffixIndex))
            } else {
                // fallback to original value without prefix
                assertionFailure("\(type(of: self)) - \(#function): . log10(value) produced NaN or infinity")
                suffixIndex = 0
                shortValue = value
            }
        }
        let suffix = suffixes[suffixIndex]
        if let shortString: String = numberFormatter.string(for: shortValue) {
            return "\(shortString)\(suffix)"
        } else {
            // fallback to string interpolation
            assertionFailure("\(type(of: self)) - \(#function): . numberFormatter returned nil result")
            return "\(shortValue)\(suffix)"
        }
    }

}
