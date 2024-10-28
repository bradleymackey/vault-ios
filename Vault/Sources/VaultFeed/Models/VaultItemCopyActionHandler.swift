import Foundation
import FoundationExtensions

@MainActor
public protocol VaultItemCopyActionHandler {
    func textToCopyForVaultItem(id: Identifier<VaultItem>) -> VaultTextCopyAction?
}
