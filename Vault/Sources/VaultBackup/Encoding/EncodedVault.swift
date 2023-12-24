import Foundation

/// An intermediate (encoded, but unencrypted) representation of a vault.
///
/// In this form, the vault is ready for either:
///  - encryption (for backup)
///  - converting to a vault payload (for the application)
public struct EncodedVault: Equatable {
    /// The raw encoded vault data.
    public var data: Data

    public init(data: Data) {
        self.data = data
    }
}
