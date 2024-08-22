import Foundation
import SwiftUI
import VaultFeed

struct VaultDetailCreateView<
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View where PreviewGenerator.PreviewItem == VaultItem.Payload {
    var creatingItem: CreatingItem
    var previewGenerator: PreviewGenerator
    @Binding var navigationPath: NavigationPath
    @Environment(VaultDataModel.self) private var dataModel
    @Environment(VaultInjector.self) private var injector

    var body: some View {
        switch creatingItem {
        case .otpCode:
            OTPCodeCreateView(
                previewGenerator: previewGenerator,
                navigationPath: $navigationPath,
                intervalTimer: injector.intervalTimer
            )
        case .secureNote:
            SecureNoteDetailView(
                newNoteWithEditor: VaultDataModelEditorAdapter(dataModel: dataModel),
                navigationPath: $navigationPath,
                dataModel: dataModel
            )
        }
    }
}
