import Foundation

/// User state of the vault feed.
@Observable
public final class VaultItemFeedState {
    var isEditing = false
    var isReordering = false

    public init() {}
}
