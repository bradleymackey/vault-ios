import Foundation

/// Compares a search query against a stored `KillphraseDigest` in
/// constant-ish time (no early exit on mismatch).
///
/// Concrete implementations must not log, throw, or otherwise leak the result
/// outside the returned `Bool`. This is the only sanctioned channel for
/// killphrase match results (MANIFESTO C2).
public protocol KillphraseMatcher: Sendable {
    func matches(query: String, salt: Data, digest: Data) -> Bool
}
