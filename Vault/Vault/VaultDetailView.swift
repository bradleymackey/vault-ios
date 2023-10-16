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
        OTPCodeDetailView(
            viewModel: .init(
                storedCode: storedItem,
                editor: VaultFeedVaultDetailEditorAdapter(vaultFeed: feedViewModel)
            )
        )
    }
}
