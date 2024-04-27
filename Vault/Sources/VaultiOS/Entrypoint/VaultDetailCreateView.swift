import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct VaultDetailCreateView<Store: VaultStore>: View {
    var feedViewModel: FeedViewModel<Store>
    var creatingItem: CreatingItem

    var body: some View {
        switch creatingItem {
        case .otpCode:
            Text("TODO: OTP Code")
        case .secureNote:
            SecureNoteDetailView(
                newNoteWithEditor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel)
            )
        case .cryptoSeedPhrase:
            Text("TODO: Crypto seed phrase")
        }
    }
}
