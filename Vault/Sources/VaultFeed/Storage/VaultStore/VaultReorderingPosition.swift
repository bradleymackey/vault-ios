import Foundation
import FoundationExtensions

public enum VaultReorderingPosition: Equatable, Hashable, Sendable {
    /// Position the item at the start of the list.
    case start
    /// Position the item relative to the given item ID, after it.
    case after(Identifier<VaultItem>)
}
