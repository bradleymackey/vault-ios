import Foundation

extension StringProtocol {
    /// The string value is only made up of whitespace or empty.
    public var isBlank: Bool {
        allSatisfy(\.isWhitespace) || isEmpty
    }

    public var isNotBlank: Bool {
        !isBlank
    }
}
