import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct VaultDetailEditView<
    Store: VaultStore,
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View
    where PreviewGenerator.PreviewItem == VaultItem.Payload
{
    var feedViewModel: FeedViewModel<Store>
    var storedItem: VaultItem
    var previewGenerator: PreviewGenerator
    var openInEditMode: Bool
    @Binding var navigationPath: NavigationPath

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        switch storedItem.item {
        case let .otpCode(storedCode):
            OTPCodeDetailView(
                editingExistingCode: storedCode,
                navigationPath: $navigationPath,
                storedMetadata: storedItem.metadata,
                editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                previewGenerator: previewGenerator,
                openInEditMode: openInEditMode,
                presentationMode: presentationMode
            )
        case let .secureNote(storedNote):
            SecureNoteDetailView(
                editingExistingNote: storedNote,
                navigationPath: $navigationPath,
                storedMetadata: storedItem.metadata,
                editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                openInEditMode: openInEditMode
            )
        }
    }
}
