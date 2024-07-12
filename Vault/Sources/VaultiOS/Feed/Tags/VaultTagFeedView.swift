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
            contentSection
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.automatic)
        .task {
            await viewModel.onAppear()
        }
    }

    private var contentSection: some View {
        Section {
            ForEach(viewModel.tags) { tag in
                VaultTagRow(tag: tag)
            }
        } header: {
            if viewModel.tags.isEmpty {
                noTagsView
            }
        }
    }

    private var noTagsView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "tag.fill")
                .font(.largeTitle)
            VStack(alignment: .center, spacing: 2) {
                Text(viewModel.strings.noTagsTitle)
                    .font(.headline.bold())
                Text(viewModel.strings.noTagsDescription)
                    .font(.callout)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding()
        .textCase(.none)
    }
}
