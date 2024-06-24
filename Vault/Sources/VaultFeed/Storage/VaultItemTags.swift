import Foundation
import VaultCore

/// Tags stored alongside vault items.
///
/// They are only identified by a unique ID to allow tag renaming to be very low-cost.
public struct VaultItemTags: Sendable, Hashable, Equatable {
    public var ids: Set<VaultItemTag.Identifier>

    public init(ids: Set<VaultItemTag.Identifier>) {
        self.ids = ids
    }
}
