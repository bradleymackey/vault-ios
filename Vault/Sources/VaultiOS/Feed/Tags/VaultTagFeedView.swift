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
            ForEach(viewModel.tags) { tag in
                VaultTagRow(tag: tag)
            }
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.automatic)
        .task {
            await viewModel.onAppear()
        }
    }
}
