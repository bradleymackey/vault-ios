import CryptoEngine
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

@MainActor
public struct VaultItemFeedView<
    Store: VaultStore & VaultTagStoreReader,
    ViewGenerator: VaultItemPreviewViewGenerator
>: View where
    ViewGenerator.PreviewItem == VaultItem.Payload
{
    @Bindable public var viewModel: FeedViewModel<Store>
    public var localSettings: LocalSettings
    public var viewGenerator: ViewGenerator
    @Binding public var isEditing: Bool
    public var gridSpacing: Double

    @State private var isReordering = false

    public init(
        viewModel: FeedViewModel<Store>,
        localSettings: LocalSettings,
        viewGenerator: ViewGenerator,
        isEditing: Binding<Bool>,
        gridSpacing: Double = 8
    ) {
        self.viewModel = viewModel
        self.localSettings = localSettings
        self.viewGenerator = viewGenerator
        _isEditing = Binding(projectedValue: isEditing)
        self.gridSpacing = gridSpacing
    }

    public var body: some View {
        VStack {
            listOfCodesView
        }
        .navigationTitle(Text(viewModel.title))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.onAppear()
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            Task {
                await viewModel.reloadData()
            }
        }
        .onChange(of: viewModel.filteringByTags) { _, _ in
            Task {
                await viewModel.reloadData()
            }
        }
    }

    private var noCodesFoundView: some View {
        PlaceholderView(systemIcon: "key.viewfinder", title: localized(key: "codeFeed.noCodes.title"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .modifier(OTPCardViewModifier())
    }

    private var reorderingBehaviour: VaultItemViewBehaviour {
        .editingState(message: nil)
    }

    private var currentBehaviour: VaultItemViewBehaviour {
        if isEditing {
            .editingState(message: localized(key: "action.tapToView"))
        } else if isReordering {
            reorderingBehaviour
        } else {
            .normal
        }
    }

    private var listOfCodesView: some View {
        ScrollView {
            LazyVGrid(columns: columns, pinnedViews: [.sectionHeaders]) {
                Section {
                    if viewModel.codes.isNotEmpty {
                        vaultItemsList
                    } else {
                        noCodesFoundView
                    }
                } header: {
                    listOfCodesHeader
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var listOfCodesHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            SearchTextField(title: viewModel.searchCodesPromptTitle, text: $viewModel.searchQuery)
            if viewModel.tags.isNotEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.tags) { tag in
                            TagPillView(tag: tag, isSelected: viewModel.filteringByTags.contains(tag.id))
                                .id(tag)
                                .onTapGesture {
                                    viewModel.toggleFiltering(tag: tag.id)
                                }
                        }
                    }
                    .font(.callout)
                }
                .scrollClipDisabled()
                if viewModel.filteringByTags.isNotEmpty {
                    filteringByTagsInfoSection
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .animation(.easeOut, value: viewModel.filteringByTags)
    }

    /// Small informational section when we are filtering by tags
    private var filteringByTagsInfoSection: some View {
        HStack {
            Text("Filtering by tags: \(viewModel.filteringByTags.count)")
                .foregroundColor(.secondary)

            Spacer()

            Button {
                viewModel.filteringByTags.removeAll()
            } label: {
                Label("Clear tags", systemImage: "xmark")
            }
            .fontWeight(.medium)
            .foregroundStyle(Color.accentColor, .secondary)
        }
        .font(.caption)
    }

    private var vaultItemsList: some View {
        ReorderableForEach(
            items: viewModel.codes,
            isDragging: $isReordering,
            isEnabled: isEditing
        ) { storedItem in
            GeometryReader { geo in
                viewGenerator.makeVaultPreviewView(
                    item: storedItem.item,
                    metadata: storedItem.metadata,
                    behaviour: currentBehaviour
                )
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .aspectRatio(1, contentMode: .fit)
            .modifier(OTPCardViewModifier(context: .secondary))
        } previewContent: { storedItem in
            GeometryReader { geo in
                viewGenerator.makeVaultPreviewView(
                    item: storedItem.item,
                    metadata: storedItem.metadata,
                    behaviour: reorderingBehaviour
                )
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .aspectRatio(1, contentMode: .fit)
            .modifier(OTPCardViewModifier())
            .frame(width: 150)
        } moveAction: { from, to in
            let movingIds = from.map { viewModel.codes[$0].id }.reducedToSet()
            let targetPosition: VaultReorderingPosition = if to == 0 {
                .start
            } else {
                .after(viewModel.codes[to - 1].id)
            }
            viewModel.codes.move(fromOffsets: from, toOffset: to)
            Task {
                try await viewModel.reorder(items: movingIds, to: targetPosition)
            }
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: gridSpacing, alignment: .top)]
    }
}

struct VaultItemFeedView_Previews: PreviewProvider {
    static var previews: some View {
        let store = VaultStoreStub()
        store.retrieveQueryResult = .init(items: [
            .init(
                metadata: .init(
                    id: Identifier<VaultItem>(),
                    created: Date(),
                    updated: Date(),
                    relativeOrder: .max,
                    userDescription: "My Cool Code",
                    tags: [],
                    visibility: .always,
                    searchableLevel: .full,
                    searchPassphrase: "",
                    lockState: .notLocked,
                    color: VaultItemColor(color: .green)
                ),
                item: .otpCode(.init(
                    type: .totp(),
                    data: .init(
                        secret: .empty(),
                        accountName: "example@example.com",
                        issuer: "i"
                    )
                ))
            ),
        ])
        return VaultItemFeedView(
            viewModel: .init(store: store),
            localSettings: .init(defaults: .init(userDefaults: .standard)),
            viewGenerator: GenericGenerator(),
            isEditing: .constant(false)
        )
    }

    struct GenericGenerator: VaultItemPreviewViewGenerator {
        func makeVaultPreviewView(
            item _: VaultItem.Payload,
            metadata _: VaultItem.Metadata,
            behaviour _: VaultItemViewBehaviour
        ) -> some View {
            Text("Code")
        }

        func scenePhaseDidChange(to _: ScenePhase) {
            // noop
        }

        func didAppear() {
            // noop
        }
    }
}
