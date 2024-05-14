import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct VaultDetailCreateView<
    Store: VaultStore,
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View where PreviewGenerator.PreviewItem == VaultItem {
    var feedViewModel: FeedViewModel<Store>
    var creatingItem: CreatingItem
    var previewGenerator: PreviewGenerator
    @Binding var navigationPath: NavigationPath

    var body: some View {
        switch creatingItem {
        case .otpCode:
            OTPCodeCreateView(
                feedViewModel: feedViewModel,
                previewGenerator: previewGenerator,
                navigationPath: $navigationPath
            )
        case .secureNote:
            SecureNoteDetailView(
                newNoteWithEditor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                navigationPath: $navigationPath
            )
        }
    }
}
