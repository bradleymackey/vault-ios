import Foundation
import FoundationExtensions

/// @mockable
@MainActor
public protocol VaultItemCopyActionHandler: Sendable {
    func textToCopyForVaultItem(id: Identifier<VaultItem>) -> VaultTextCopyAction?
}
