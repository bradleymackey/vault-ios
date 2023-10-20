import Foundation

/// Encapsulates the edit state for a given code.
///
/// This is a partial edit to the code, as seen from the user's point of view.
public struct OTPCodeDetailEdits: Equatable {
    public var issuerTitle: String
    public var accountNameTitle: String
    public var description: String

    public init(issuerTitle: String = "", accountNameTitle: String = "", description: String = "") {
        self.issuerTitle = issuerTitle
        self.accountNameTitle = accountNameTitle
        self.description = description
    }
}
