import Foundation
import SwiftUI
import VaultCore
import VaultFeed
import VaultFeediOS

struct VaultDetailView<Store: VaultStore>: View {
    @Environment(\.dismiss) var dismiss

    var feedViewModel: FeedViewModel<Store>
    let storedCode: StoredVaultItem

    var body: some View {
        OTPCodeDetailView(
            viewModel: .init(storedCode: storedCode, editor: CodeFeedCodeDetailEditorAdapter(codeFeed: feedViewModel))
        )
    }
}
