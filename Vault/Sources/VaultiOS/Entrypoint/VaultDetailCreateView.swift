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

    var body: some View {
        switch creatingItem {
        case .otpCode:
            OTPCodeDetailView(
                newCodeWithEditor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                previewGenerator: previewGenerator
            )
        case .secureNote:
            SecureNoteDetailView(
                newNoteWithEditor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel)
            )
        case .cryptoSeedPhrase:
            Text("TODO: Crypto seed phrase")
        }
    }
}
