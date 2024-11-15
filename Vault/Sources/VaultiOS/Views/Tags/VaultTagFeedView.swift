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
            list
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

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .top)]
    }

    private func tagViewPreview(tag: VaultItemTag) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer()
            TagPillView(tag: tag, isSelected: true)
                .font(.body)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.8, contentMode: .fill)
        .modifier(
            VaultCardModifier(
                configuration: .init(
                    style: .secondary,
                    border: tag.color.color,
                    padding: .init(all: 8)
                )
            )
        )
    }

    private var list: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns) {
                switch dataModel.allTagsState {
                case .base, .loading:
                    loadingTagsView
                case .loaded:
                    if dataModel.allTags.isEmpty {
                        noTagsFoundView
                    } else {
                        ForEach(dataModel.allTags) { tag in
                            Button {
                                modal = .editingTag(tag)
                            } label: {
                                tagViewPreview(tag: tag)
                            }
                        }
                    }
                }
            }
            .padding(.top, 4)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var loadingTagsView: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer()
            ProgressView()
            Spacer()
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1.8, contentMode: .fit)
        .modifier(VaultCardModifier(configuration: .init(style: .secondary, border: .secondary)))
    }

    private var noTagsFoundView: some View {
        VStack(alignment: .center, spacing: 12) {
            Label(viewModel.strings.noTagsTitle, systemImage: "tag")
                .font(.callout)
        }
        .textCase(.none)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1.8, contentMode: .fit)
        .modifier(VaultCardModifier(configuration: .init(style: .secondary, border: .secondary)))
    }
}
