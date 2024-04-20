import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
struct SecureNoteDetailView: View {
    @Bindable var viewModel: SecureNoteDetailViewModel

    var body: some View {
        Form {
            Text("Secure Note")
        }
    }
}
