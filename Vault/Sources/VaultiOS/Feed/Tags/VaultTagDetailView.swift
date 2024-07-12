import Foundation
import SwiftUI
import VaultFeed

struct VaultTagDetailView<Store: VaultTagStore>: View {
    @State private var viewModel: VaultTagDetailViewModel<Store>

    init(viewModel: VaultTagDetailViewModel<Store>) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            Text("Editing Tag")
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
