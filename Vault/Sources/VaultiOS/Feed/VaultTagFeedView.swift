import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct VaultTagFeedView: View {
    var viewModel: VaultTagFeedViewModel

    init(viewModel: VaultTagFeedViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            Text("This is a tag item")
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.automatic)
    }
}
