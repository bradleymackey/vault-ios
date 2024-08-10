import Foundation
import FoundationExtensions
import SwiftUI
import VaultFeed

@MainActor
struct VaultTagFeedView<Store: VaultTagStore>: View {
    @State private var viewModel: VaultTagFeedViewModel<Store>
    @State private var modal: Modal?

    @Environment(\.dismiss) private var dismiss

    init(viewModel: VaultTagFeedViewModel<Store>) {
        self.viewModel = viewModel
    }

    enum Modal: Hashable, IdentifiableSelf {
        case creatingTag
        case editingTag(VaultItemTag)
    }

    var body: some View {
        VStack {
            switch viewModel.state {
            case .base:
                // Initially empty view before loaded so we don't flash the noTagsView
                EmptyView()
            case .loaded:
                if viewModel.tags.isEmpty {
                    noTagsView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    list
                }
            }
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    modal = .creatingTag
                } label: {
                    Label(viewModel.strings.createTagTitle, systemImage: "plus")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
        .sheet(item: $modal, onDismiss: nil) { content in
            switch content {
            case .creatingTag:
                NavigationStack {
                    VaultTagDetailView<Store>(
                        viewModel: .init(store: viewModel.store, existingTag: nil),
                        didUpdateItems: {
                            await viewModel.reloadData()
                        }
                    )
                }
            case let .editingTag(tag):
                NavigationStack {
                    VaultTagDetailView<Store>(
                        viewModel: .init(store: viewModel.store, existingTag: tag),
                        didUpdateItems: {
                            await viewModel.reloadData()
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(viewModel.tags) { tag in
                    Button {
                        modal = .editingTag(tag)
                    } label: {
                        FormRow(
                            image: Image(systemName: tag.iconName ?? VaultItemTag.defaultIconName),
                            color: tag.color?.color ?? .primary,
                            style: .standard
                        ) {
                            Text(tag.name)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var noTagsView: some View {
        PlaceholderView(
            systemIcon: "tag.fill",
            title: viewModel.strings.noTagsTitle,
            subtitle: viewModel.strings.noTagsDescription
        )
        .containerRelativeFrame(.horizontal)
        .modifier(VerticallyCenterUpperThird(alignment: .center))
        .padding(24)
    }
}
