import Foundation
import FoundationExtensions

public enum VaultItemSearchableLevel: Equatable, Hashable, IdentifiableSelf, Sendable {
    /// The item cannot be searched for.
    case none
    /// All available data in the item can be searched for.
    case full
    /// Only the title of the item can be searched for.
    case onlyTitle
    /// A secret passphrase is required to search.
    case onlyPassphrase
}
