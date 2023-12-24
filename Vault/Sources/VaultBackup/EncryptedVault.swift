import Foundation

public struct EncryptedVault {
    /// The encrypted payload after encryption.
    public var data: Data
    /// Additional data that represents authentication.
    public var authentication: Data
}
