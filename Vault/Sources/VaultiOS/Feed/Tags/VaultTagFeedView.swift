import Foundation
import FoundationExtensions
import SwiftUI
import VaultFeed

@MainActor
struct VaultTagFeedView<Store: VaultTagStore>: View {
    var viewModel: VaultTagFeedViewModel<Store>
    @State private var modal: Modal?

    init(viewModel: VaultTagFeedViewModel<Store>) {
        self.viewModel = viewModel
    }

    enum Modal: Hashable, IdentifiableSelf {
        case creatingTag
        case editingTag(VaultItemTag)
    }

    var body: some View {
        VStack {
            if viewModel.tags.isEmpty {
                noTagsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                list
            }
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.automatic)
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
                        TagPillView(tag: tag, isSelected: true)
                    }
                    .buttonStyle(.plain)
                    .modifier(HorizontallyCenter())
                    .listRowSeparator(.hidden)
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
        .modifier(VerticallyCenterUpperThird(alignment: .center))
        .padding(24)
    }
}
