import Foundation

public final class GenericVaultItemCopyActionHandler: VaultItemCopyActionHandler {
    private let childHandlers: [any VaultItemCopyActionHandler]

    public init(childHandlers: [any VaultItemCopyActionHandler]) {
        self.childHandlers = childHandlers
    }

    public func textToCopyForVaultItem(id: Identifier<VaultItem>) -> VaultTextCopyAction? {
        for childHandler in childHandlers {
            if let action = childHandler.textToCopyForVaultItem(id: id) {
                return action
            }
        }
        return nil
    }
}
