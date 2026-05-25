import Foundation

/// Classifies the sensitivity of a value being copied to the system pasteboard.
///
/// Used to decide per-type whether the value may be synced to iCloud Universal Clipboard.
public enum PasteboardContentType: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    /// A long-lived credential such as a password.
    case password
    /// A short-lived one-time code (TOTP/HOTP).
    case otp
    /// Any other sensitive value that does not fit the categories above.
    case other
}
