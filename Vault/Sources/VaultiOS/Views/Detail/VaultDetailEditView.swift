import Foundation
import SwiftUI
import VaultFeed

struct VaultDetailEditView<
    PreviewGenerator: VaultItemPreviewViewGenerator<VaultItem.Payload>
>: View {
    var storedItem: VaultItem
    var previewGenerator: PreviewGenerator
    var copyActionHandler: any VaultItemCopyActionHandler
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
                copyActionHandler: copyActionHandler,
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
        case .encryptedItem:
            Text("Coming soon...")
        }
    }
}
