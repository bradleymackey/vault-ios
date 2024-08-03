import Foundation
import FoundationExtensions

public enum VaultReorderingPosition: Equatable, Hashable {
    /// Position the item relative to the given item ID, before it.
    case before(Identifier<VaultItem>)
    /// Position the item relative to the given item ID, after it.
    case after(Identifier<VaultItem>)

    public var id: Identifier<VaultItem> {
        switch self {
        case let .before(id), let .after(id): id
        }
    }
}
