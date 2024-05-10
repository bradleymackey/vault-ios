import Foundation

extension StringProtocol {
    /// The string value is only made up of whitespace.
    public var isBlank: Bool {
        allSatisfy(\.isWhitespace)
    }
}
