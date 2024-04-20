import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct VaultDetailView<
    Store: VaultStore,
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View
    where PreviewGenerator.PreviewItem == VaultItem
{
    @Environment(\.dismiss) var dismiss

    var feedViewModel: FeedViewModel<Store>
    var storedItem: StoredVaultItem
    var previewGenerator: PreviewGenerator

    var body: some View {
        switch storedItem.item {
        case let .otpCode(storedCode):
            OTPCodeDetailView(
                viewModel: .init(
                    storedCode: storedCode,
                    storedMetadata: storedItem.metadata,
                    editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel)
                ),
                previewGenerator: previewGenerator
            )
        case let .secureNote(storedNote):
            SecureNoteDetailView(
                viewModel: .init(
                    storedNote: storedNote,
                    storedMetadata: storedItem.metadata,
                    editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel)
                )
            )
        }
    }
}
