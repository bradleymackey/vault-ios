import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct VaultTagFeedView: View {
    @State private var viewModel: VaultTagFeedViewModel
    @State private var modal: Modal?

    @Environment(VaultDataModel.self) private var dataModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: VaultTagFeedViewModel) {
        self.viewModel = viewModel
    }

    enum Modal: Hashable, IdentifiableSelf {
        case creatingTag
        case editingTag(VaultItemTag)
    }

    var body: some View {
        VStack {
            switch dataModel.allTagsState {
            case .base, .loading:
                // Initially empty view before loaded so we don't flash the noTagsView
                EmptyView()
            case .loaded:
                list
            }
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    modal = .creatingTag
                } label: {
                    Label(viewModel.strings.createTagTitle, systemImage: "plus")
                }
            }
        }
        .sheet(item: $modal, onDismiss: nil) { content in
            switch content {
            case .creatingTag:
                NavigationStack {
                    VaultTagDetailView(
                        viewModel: .init(dataModel: dataModel, existingTag: nil)
                    )
                }
            case let .editingTag(tag):
                NavigationStack {
                    VaultTagDetailView(
                        viewModel: .init(dataModel: dataModel, existingTag: tag)
                    )
                }
            }
        }
    }

    private var list: some View {
        Form {
            Section {
                if dataModel.allTags.isEmpty {
                    noTagsView
                } else {
                    ForEach(dataModel.allTags) { tag in
                        Button {
                            modal = .editingTag(tag)
                        } label: {
                            FormRow(
                                image: Image(systemName: tag.iconName),
                                color: tag.color.color,
                                style: .standard
                            ) {
                                Text(tag.name)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let ids = indexSet.map { dataModel.allTags[$0].id }
                        Task {
                            for id in ids {
                                try await dataModel.delete(tagID: id)
                            }
                        }
                    }
                }
            }
        }
    }

    private var noTagsView: some View {
        PlaceholderView(
            systemIcon: "tag.fill",
            title: viewModel.strings.noTagsTitle,
            subtitle: viewModel.strings.noTagsDescription
        )
        .containerRelativeFrame(.horizontal)
        .padding()
    }
}
