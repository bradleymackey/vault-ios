import Foundation

public enum VaultReorderingPosition {
    /// Position the item relative to the given item ID, before it.
    case before(UUID)
    /// Position the item relative to the given item ID, after it.
    case after(UUID)

    public var id: UUID {
        switch self {
        case let .before(uuid), let .after(uuid): uuid
        }
    }
}
