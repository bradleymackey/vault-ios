import Foundation
import OTPCore

/// An `OTPAuthCode` retrieved from storage.
///
/// Includes the unique ID used to identify this code.
public struct StoredOTPCode: Equatable, Identifiable {
    /// A unique ID to identify this specific `code`.
    public var id: UUID
    /// The stored code value.
    public var code: OTPAuthCode

    public init(id: UUID, code: OTPAuthCode) {
        self.id = id
        self.code = code
    }
}
