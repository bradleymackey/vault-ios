import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct VaultDetailEditView<
    Store: VaultStore & VaultTagStore,
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View
    where PreviewGenerator.PreviewItem == VaultItem.Payload
{
    var feedViewModel: FeedViewModel<Store>
    var storedItem: VaultItem
    var previewGenerator: PreviewGenerator
    var openInEditMode: Bool
    @Binding var navigationPath: NavigationPath

    @Environment(VaultDataModel.self) private var dataModel
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        switch storedItem.item {
        case let .otpCode(storedCode):
            OTPCodeDetailView(
                editingExistingCode: storedCode,
                navigationPath: $navigationPath,
                dataModel: dataModel,
                storedMetadata: storedItem.metadata,
                editor: VaultDataModelEditorAdapter(dataModel: dataModel),
                previewGenerator: previewGenerator,
                openInEditMode: openInEditMode,
                presentationMode: presentationMode
            )
        case let .secureNote(storedNote):
            SecureNoteDetailView(
                editingExistingNote: storedNote,
                navigationPath: $navigationPath,
                dataModel: dataModel,
                storedMetadata: storedItem.metadata,
                editor: VaultDataModelEditorAdapter(dataModel: dataModel),
                openInEditMode: openInEditMode
            )
        }
    }
}
