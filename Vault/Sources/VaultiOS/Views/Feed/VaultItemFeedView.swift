import CryptoEngine
import SwiftUI
import VaultFeed
import VaultSettings

@MainActor
struct VaultItemFeedView<
    ViewGenerator: VaultItemPreviewViewGenerator
>: View where
    ViewGenerator.PreviewItem == VaultItem.Payload
{
    var localSettings: LocalSettings
    var viewGenerator: ViewGenerator
    var gridSpacing: Double

    @Environment(VaultInjector.self) private var injector
    @Environment(VaultDataModel.self) private var dataModel
    @State private var state: VaultItemFeedState

    init(
        localSettings: LocalSettings,
        viewGenerator: ViewGenerator,
        state: VaultItemFeedState,
        gridSpacing: Double = 8
    ) {
        self.localSettings = localSettings
        self.viewGenerator = viewGenerator
        self.state = state
        self.gridSpacing = gridSpacing
    }

    var body: some View {
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
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .modifier(VaultCardModifier())
    }

    private var currentBehaviour: VaultItemViewBehaviour {
        if state.isEditing {
            .editingState(message: localized(key: "action.tapToView"))
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

    @State private var targetedIds = Set<Identifier<VaultItem>>()

    private var vaultItemsList: some View {
        ForEach(dataModel.items) { storedItem in
            viewGenerator.makeVaultPreviewView(
                item: storedItem.item,
                metadata: storedItem.metadata,
                behaviour: currentBehaviour
            )
            .opacity(targetedIds.contains(storedItem.id) ? 0.5 : 1)
            .id(storedItem.id)
            .draggable(storedItem)
            .if(state.isEditing) {
                $0.dropDestination(for: Identifier<VaultItem>.self) { dropItems, _ in
                    guard dropItems.count == 1 else { return false }
                    guard let dropItem = dropItems.first else { return false }
                    guard dropItem != storedItem.id else { return false }
                    guard let from = dataModel.items.firstIndex(where: { $0.id == dropItem }),
                          let to = dataModel.items.firstIndex(where: { $0.id == storedItem.id })
                    else {
                        return false
                    }
                    guard dataModel.items[to].id != dropItem else { return false }
                    guard to != from else { return false }
                    let targetPosition: VaultReorderingPosition = if to == 0 {
                        .start
                    } else {
                        .after(dataModel.items[to - 1].id)
                    }
                    withAnimation {
                        dataModel.items.move(fromOffsets: [from], toOffset: to)
                    }
                    Task {
                        try await dataModel.reorder(items: [dropItem], to: targetPosition)
                    }
                    return true
                } isTargeted: { isTarget in
                    if isTarget {
                        targetedIds.insert(storedItem.id)
                    } else {
                        targetedIds.remove(storedItem.id)
                    }
                }
            }
        }
        // Reload content when editing state changes.
        // The content needs to rerender when the editing state changes.
        .id(state.isEditing)
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: gridSpacing, alignment: .top)]
    }
}

#Preview {
    let store = VaultStoreStub()
    let dataModel = VaultDataModel(
        vaultStore: store,
        vaultTagStore: VaultTagStoreStub(),
        vaultImporter: VaultStoreImporterMock(),
        vaultDeleter: VaultStoreDeleterMock(),
        backupPasswordStore: BackupPasswordStoreMock(),
        backupEventLogger: BackupEventLoggerMock()
    )
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
        state: VaultItemFeedState()
    )
    .environment(dataModel)
}

private struct GenericGenerator: VaultItemPreviewViewGenerator {
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
