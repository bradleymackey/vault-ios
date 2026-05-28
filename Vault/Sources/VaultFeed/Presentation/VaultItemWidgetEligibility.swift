import Foundation

/// Determines whether a `VaultItem` may be surfaced in a home-screen / lock-screen widget.
///
/// Eligibility is **derived** from existing metadata fields rather than persisted as a
/// per-item flag. A widget is a public surface — exposing an OTP code on it is a
/// reduction in protection — so we never include items the user has marked as in any
/// way sensitive: locked items, items hidden from the feed, items reachable only via
/// search passphrase, and items protected by a killphrase.
///
/// The "opt-in" surface is the widget's configuration sheet, where the user picks
/// from the set of items that pass this filter.
public enum VaultItemWidgetEligibility {
    /// Whether the given item may appear in the widget configuration picker and be
    /// rendered by a widget timeline.
    ///
    /// An item is eligible iff every condition below holds:
    /// - the payload is an `.otpCode`
    /// - `lockState == .notLocked`
    /// - `visibility == .always`
    /// - `searchableLevel != .onlyPassphrase`
    /// - `killphrase == nil`
    ///
    /// All five must hold; this is intentionally stricter than autofill eligibility,
    /// which permits items hidden from the feed.
    public static func isEligible(_ item: VaultItem) -> Bool {
        guard case .otpCode = item.item else { return false }
        return isEligible(metadata: item.metadata)
    }

    /// Metadata-only overload used by edit-screen code paths that have not yet
    /// produced a full `VaultItem`. Callers must verify the payload is an OTP code
    /// separately.
    public static func isEligible(metadata: VaultItem.Metadata) -> Bool {
        metadata.lockState == .notLocked
            && metadata.visibility == .always
            && metadata.searchableLevel != .onlyPassphrase
            && metadata.killphrase == nil
    }
}
