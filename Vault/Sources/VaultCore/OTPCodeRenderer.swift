import CryptoEngine
import Foundation

public struct OTPCodeRenderer {
    public init() {}

    struct InvalidLengthError: Error {}

    public func render(code: BigUInt, digits: UInt16) throws -> String {
        let initialString = String(code)
        guard initialString.count <= digits else { throw InvalidLengthError() }
        return initialString.leftPadding(toLength: Int(digits), withPad: "0")
    }
}

extension String {
    fileprivate func leftPadding(toLength newLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < newLength {
            return String(repeatElement(character, count: newLength - stringLength)) + self
        } else {
            return String(suffix(newLength))
        }
    }
}
