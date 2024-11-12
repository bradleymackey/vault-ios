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
    @Environment(VaultInjector.self) private var injector
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        switch storedItem.item {
        case let .otpCode(code):
            OTPCodeDetailView(
                editingExistingCode: code,
                navigationPath: $navigationPath,
                dataModel: dataModel,
                storedMetadata: storedItem.metadata,
                editor: VaultDataModelEditorAdapter(dataModel: dataModel),
                previewGenerator: previewGenerator,
                copyActionHandler: copyActionHandler,
                openInEditMode: openInEditMode,
                presentationMode: presentationMode
            )
        case let .secureNote(note):
            SecureNoteDetailView(
                editingExistingNote: note,
                navigationPath: $navigationPath,
                dataModel: dataModel,
                storedMetadata: storedItem.metadata,
                editor: VaultDataModelEditorAdapter(dataModel: dataModel),
                openInEditMode: openInEditMode
            )
        case let .encryptedItem(item):
            EncryptedItemDetailView(
                viewModel: .init(
                    item: item,
                    keyDeriverFactory: injector.vaultKeyDeriverFactory
                ),
                presentationMode: presentationMode
            )
        }
    }
}
