import Foundation
import SwiftUI
import VaultCore
import VaultFeed
import VaultFeediOS

struct VaultDetailView<Store: VaultStore>: View {
    @Environment(\.dismiss) var dismiss

    var feedViewModel: FeedViewModel<Store>
    let storedItem: StoredVaultItem

    var body: some View {
        switch storedItem.item {
        case let .otpCode(storedCode):
            OTPCodeDetailView(
                viewModel: .init(
                    storedCode: storedCode,
                    storedMetadata: storedItem.metadata,
                    editor: VaultFeedVaultDetailEditorAdapter(vaultFeed: feedViewModel)
                )
            )
        case .secureNote:
            Text("Secure Note")
        }
    }
}
