import Foundation

extension FloatingPoint {
    /// Returns true if the value is approximately equal to another value within a given tolerance.
    ///
    /// This is useful for Swift Testing assertions where you need to compare floating-point values
    /// with some allowed margin of error.
    ///
    /// Usage:
    /// ```swift
    /// #expect(value.isApproximatelyEqual(to: 0.69, absoluteTolerance: .ulpOfOne))
    /// ```
    public func isApproximatelyEqual(to other: Self, absoluteTolerance tolerance: Self) -> Bool {
        abs(self - other) <= tolerance
    }
}
