import Foundation

/// Compares a search query against a stored `SearchPassphraseDigest` in
/// constant-ish time (no early exit on mismatch).
///
/// Concrete implementations must apply the same Unicode case fold to the
/// query that was applied to the original phrase before digesting, so that
/// matching remains case-insensitive across normalization variants.
public protocol SearchPassphraseMatcher: Sendable {
    func matches(query: String, salt: Data, digest: Data) -> Bool
}
