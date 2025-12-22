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
        Group {
            switch dataModel.allTagsState {
            case .base, .loading:
                ProgressView()
            case .loaded:
                if dataModel.allTags.isEmpty {
                    ContentUnavailableView {
                        Label(viewModel.strings.noTagsTitle, systemImage: "tag")
                    }
                } else {
                    list
                }
            }
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if dataModel.allTags.isNotEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
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
                        viewModel: .init(dataModel: dataModel, existingTag: nil),
                    )
                }
            case let .editingTag(tag):
                NavigationStack {
                    VaultTagDetailView(
                        viewModel: .init(dataModel: dataModel, existingTag: tag),
                    )
                }
            }
        }
    }

    private var list: some View {
        List {
            ForEach(dataModel.allTags) { tag in
                Button {
                    modal = .editingTag(tag)
                } label: {
                    Label {
                        Text(tag.name)
                            .foregroundStyle(tag.listRowForegroundColor())
                    } icon: {
                        Image(systemName: tag.iconName)
                            .foregroundStyle(tag.listRowForegroundColor())
                    }
                    .contentShape(Rectangle())
                }
                .listRowBackground(tag.listRowBackgroundColor())
            }
            .onDelete { indexSet in
                deleteTag(at: indexSet)
            }
        }
    }

    private func deleteTag(at indexSet: IndexSet) {
        Task {
            for index in indexSet {
                let tag = dataModel.allTags[index]
                try? await dataModel.delete(tagID: tag.id)
            }
        }
    }
}
