import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct VaultTagFeedView<Store: VaultTagStore>: View {
    var viewModel: VaultTagFeedViewModel<Store>

    init(viewModel: VaultTagFeedViewModel<Store>) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            VaultTagRow(tag: .init(id: .init(id: UUID()), name: "Testing"))
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.automatic)
        .task {}
    }
}
