import CryptoEngine
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

@MainActor
public struct VaultItemFeedView<
    ViewGenerator: VaultItemPreviewViewGenerator
>: View where
    ViewGenerator.PreviewItem == VaultItem.Payload
{
    public var localSettings: LocalSettings
    public var viewGenerator: ViewGenerator
    @Binding public var isEditing: Bool
    public var gridSpacing: Double

    @Environment(VaultDataModel.self) private var dataModel
    @State private var isReordering = false

    public init(
        localSettings: LocalSettings,
        viewGenerator: ViewGenerator,
        isEditing: Binding<Bool>,
        gridSpacing: Double = 8
    ) {
        self.localSettings = localSettings
        self.viewGenerator = viewGenerator
        _isEditing = Binding(projectedValue: isEditing)
        self.gridSpacing = gridSpacing
    }

    public var body: some View {
        VStack {
            listOfCodesView
        }
        .navigationTitle(Text(dataModel.feedTitle))
        .task {
            await dataModel.reloadData()
        }
        .onChange(of: dataModel.itemsSearchQuery) { _, _ in
            Task {
                await dataModel.reloadItems()
            }
        }
        .onChange(of: dataModel.itemsFilteringByTags) { _, _ in
            Task {
                await dataModel.reloadItems()
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
                    if dataModel.items.isNotEmpty {
                        vaultItemsList
                    } else {
                        noCodesFoundView
                    }
                } header: {
                    listOfCodesHeader
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal)
            .padding(.bottom)
        }
        .scrollTargetBehavior(.viewAligned)
    }

    private var listOfCodesHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            @Bindable var dataModel = dataModel
            SearchTextField(title: "Search", text: $dataModel.itemsSearchQuery)
            if dataModel.allTags.isNotEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(dataModel.allTags) { tag in
                            TagPillView(tag: tag, isSelected: dataModel.itemsFilteringByTags.contains(tag.id))
                                .id(tag)
                                .onTapGesture {
                                    dataModel.toggleFiltering(tag: tag.id)
                                }
                        }
                    }
                    .font(.callout)
                }
                .scrollClipDisabled()
                if dataModel.itemsFilteringByTags.isNotEmpty {
                    filteringByTagsInfoSection
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .animation(.easeOut, value: dataModel.itemsFilteringByTags)
    }

    /// Small informational section when we are filtering by tags
    private var filteringByTagsInfoSection: some View {
        HStack {
            Text("Filtering by tags: \(dataModel.itemsFilteringByTags.count)")
                .foregroundColor(.secondary)

            Spacer()

            Button {
                dataModel.itemsFilteringByTags.removeAll()
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
            items: dataModel.items,
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
            let movingIds = from.map { dataModel.items[$0].id }.reducedToSet()
            let targetPosition: VaultReorderingPosition = if to == 0 {
                .start
            } else {
                .after(dataModel.items[to - 1].id)
            }
            dataModel.items.move(fromOffsets: from, toOffset: to)
            Task {
                try await dataModel.reorder(items: movingIds, to: targetPosition)
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
        store.retrieveHandler = { _ in .init(items: [
            .init(
                metadata: .init(
                    id: Identifier<VaultItem>(),
                    created: Date(),
                    updated: Date(),
                    relativeOrder: .min,
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
        }
        return VaultItemFeedView(
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
