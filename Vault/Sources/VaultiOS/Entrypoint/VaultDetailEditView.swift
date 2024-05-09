import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct VaultDetailEditView<
    Store: VaultStore,
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View
    where PreviewGenerator.PreviewItem == VaultItem
{
    var feedViewModel: FeedViewModel<Store>
    var storedItem: StoredVaultItem
    var previewGenerator: PreviewGenerator
    var openInEditMode: Bool

    var body: some View {
        switch storedItem.item {
        case let .otpCode(storedCode):
            OTPCodeDetailView(
                editingExistingCode: storedCode,
                storedMetadata: storedItem.metadata,
                editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                previewGenerator: previewGenerator,
                openInEditMode: openInEditMode
            )
        case let .secureNote(storedNote):
            SecureNoteDetailView(
                editingExistingNote: storedNote,
                storedMetadata: storedItem.metadata,
                editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                openInEditMode: openInEditMode
            )
        }
    }
}
