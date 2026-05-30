import Foundation

/// One-way digest representing an item's search passphrase.
///
/// Stored in place of the plaintext phrase. The digest is computed as
/// `HMAC-SHA256(K, salt || fold(phrase))` where `K` is a device-scoped HMAC
/// key and `fold(...)` is a Unicode-aware case fold that preserves the
/// case-insensitive matching the prior plaintext predicate provided.
public struct SearchPassphraseDigest: Equatable, Hashable, Sendable, Codable {
    /// Per-item random salt mixed into the HMAC input.
    public let salt: Data
    /// HMAC-SHA256 output over `salt || fold(phrase)`.
    public let digest: Data

    public init(salt: Data, digest: Data) {
        self.salt = salt
        self.digest = digest
    }
}
