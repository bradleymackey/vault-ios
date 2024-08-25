import CryptoEngine
import Foundation

public struct OTPCodeRenderer {
    public init() {}

    public func render(code: BigUInt, digits: UInt16) -> String {
        let initialString = String(code)
        return initialString.otpLeftPadding(toLength: Int(digits), withPad: "0")
    }
}

extension String {
    fileprivate func otpLeftPadding(toLength newLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < newLength {
            return String(repeatElement(character, count: newLength - stringLength)) + self
        } else {
            // If the string is longer than the length, we just use the suffix.
            return String(suffix(newLength))
        }
    }
}
