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
                ToolbarItem(placement: .secondaryAction) {
                    EditButton()
                }
            }
            ToolbarItem(placement: .primaryAction) {
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
                            .foregroundStyle(tagForegroundColor(for: tag))
                    } icon: {
                        Image(systemName: tag.iconName)
                            .foregroundStyle(tagForegroundColor(for: tag))
                    }
                    .contentShape(Rectangle())
                }
                .listRowBackground(tagBackgroundColor(for: tag))
            }
            .onDelete { indexSet in
                deleteTag(at: indexSet)
            }
        }
    }

    private func tagForegroundColor(for tag: VaultItemTag) -> Color {
        let baseColor = tag.color.color

        // If color is too light or dark for default list background, use contrasting color
        if baseColor.isPercievedLight || baseColor.isPercievedDark {
            return baseColor.contrastingForegroundColor
        }

        return baseColor
    }

    private func tagBackgroundColor(for tag: VaultItemTag) -> Color? {
        let baseColor = tag.color.color

        // Add subtle tinted background for light/dark colors to improve visibility
        if baseColor.isPercievedLight {
            return baseColor.opacity(0.15)
        } else if baseColor.isPercievedDark {
            return baseColor.opacity(0.2)
        }

        return nil
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
