import Foundation
import VaultFeed

func anyVaultItemMetadata(
    lockState: VaultItemLockState = .notLocked
) -> VaultItem.Metadata {
    .init(
        id: Identifier<VaultItem>(),
        created: Date(),
        updated: Date(),
        relativeOrder: .min,
        userDescription: "any",
        tags: [],
        visibility: .always,
        searchableLevel: .full,
        searchPassphrase: "",
        lockState: lockState,
        color: .black
    )
}

func anyVaultItem() -> VaultItem {
    VaultItem(
        metadata: anyVaultItemMetadata(),
        item: .secureNote(.init(title: "hello", contents: "hello", format: .markdown))
    )
}
