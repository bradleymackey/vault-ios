import CryptoEngine
import SwiftUI
import VaultFeed
import VaultSettings

@MainActor
public struct VaultItemFeedView<
    ViewGenerator: VaultItemPreviewViewGenerator,
>: View where
    ViewGenerator.PreviewItem == VaultItem.Payload
{
    var localSettings: LocalSettings
    var viewGenerator: ViewGenerator
    var gridSpacing: Double

    @Environment(VaultInjector.self) private var injector
    @Environment(VaultDataModel.self) private var dataModel
    @State private var state: VaultItemFeedState

    public init(
        localSettings: LocalSettings,
        viewGenerator: ViewGenerator,
        state: VaultItemFeedState,
        gridSpacing: Double = 8,
    ) {
        self.localSettings = localSettings
        self.viewGenerator = viewGenerator
        self.state = state
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
        VStack(alignment: .center, spacing: 12) {
            Label(localized(key: "codeFeed.noCodes.title"), systemImage: "key.horizontal")
                .font(.callout)
        }
        .textCase(.none)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .modifier(VaultCardModifier(configuration: .init(style: .secondary, border: .secondary)))
    }

    private var currentBehaviour: VaultItemViewBehaviour {
        if state.isEditing {
            .editingState(message: localized(key: "action.tapToView"))
        } else {
            .normal
        }
    }

    private var listOfCodesView: some View {
        @Bindable var dataModel = dataModel
        return ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns) {
                Section {
                    if dataModel.items.isNotEmpty {
                        vaultItemsList
                    } else {
                        noCodesFoundView
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal)
            .padding(.bottom)
            .animation(.easeOut(duration: 0.1), value: dataModel.itemsFilteringByTags)
        }
        .searchable(text: $dataModel.itemsSearchQuery)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if state.isEditing {
                    editModeInfoSection
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if dataModel.allTags.isNotEmpty {
                    filteringByTagsSection
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dataModel.allTags.isEmpty)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.isEditing)
        }
    }

    private var filteringByTagsSection: some View {
        VStack(spacing: 8) {
            if dataModel.itemsFilteringByTags.isNotEmpty {
                filteringByTagsInfoSection
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

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
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dataModel.itemsFilteringByTags)
    }

    /// Informational section when we are filtering by tags
    private var filteringByTagsInfoSection: some View {
        HStack {
            Text(dataModel.filteringByTagsDescription)
                .foregroundColor(.secondary)
                .font(.subheadline)

            Spacer()

            Button {
                dataModel.itemsFilteringByTags.removeAll()
            } label: {
                Label("Clear", systemImage: "xmark.circle.fill")
            }
            .fontWeight(.semibold)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.accentColor)
            .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Informational section when in edit mode
    private var editModeInfoSection: some View {
        HStack {
            Label {
                Text(localized(key: "codeFeed.editMode.dragToReorder"))
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } icon: {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @State private var targetedIds = Set<Identifier<VaultItem>>()

    private var vaultItemsList: some View {
        ForEach(dataModel.items) { storedItem in
            viewGenerator.makeVaultPreviewView(
                item: storedItem.item,
                metadata: storedItem.metadata,
                behaviour: currentBehaviour,
            )
            .id(makeID(item: storedItem))
            .opacity(targetedIds.contains(storedItem.id) ? 0.5 : 1)
            .draggable(storedItem)
            .if(state.isEditing) {
                $0.dropDestination(for: Identifier<VaultItem>.self) { dropItems, _ in
                    // Semantically, it only makes sense to move or drag a single item at once.
                    guard dropItems.count == 1, let dropItem = dropItems.first else {
                        return false
                    }
                    let reorderer = VaultItemFeedReorderer(state: dataModel.items.map(\.id))
                    let move = reorderer.reorder(item: dropItem, to: storedItem.id)
                    switch move {
                    case .noMove:
                        return false
                    case let .move(move):
                        withAnimation {
                            dataModel.items.move(fromOffsets: [move.fromIndex], toOffset: move.toIndex)
                        }
                        Task {
                            try await dataModel.reorder(items: [dropItem], to: move.reorderingPosition)
                        }
                        return true
                    }
                } isTargeted: { isTarget in
                    if isTarget {
                        targetedIds.insert(storedItem.id)
                    } else {
                        targetedIds.remove(storedItem.id)
                    }
                }
            }
        }
        .onChange(of: state.isEditing) { _, isEditing in
            if !isEditing { targetedIds.removeAll() }
        }
    }

    private func makeID(item: VaultItem) -> some Hashable {
        var hasher = Hasher()
        hasher.combine(item.id)
        hasher.combine(state.isEditing)
        hasher.combine(dataModel.itemSearchHash)
        return hasher.finalize()
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
        vaultKillphraseDeleter: VaultStoreKillphraseDeleterMock(),
        vaultOtpAutofillStore: VaultOTPAutofillStoreMock(),
        backupPasswordStore: BackupPasswordStoreMock(),
        backupEventLogger: BackupEventLoggerMock(),
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
                killphrase: "",
                lockState: .notLocked,
                color: VaultItemColor(color: .green),
            ),
            item: .otpCode(.init(
                type: .totp(),
                data: .init(
                    secret: .empty(),
                    accountName: "example@example.com",
                    issuer: "i",
                ),
            )),
        ),
    ])
    }
    return VaultItemFeedView(
        localSettings: .init(defaults: .init(userDefaults: .standard)),
        viewGenerator: GenericGenerator(),
        state: VaultItemFeedState(),
    )
    .environment(dataModel)
}

private struct GenericGenerator: VaultItemPreviewViewGenerator {
    func makeVaultPreviewView(
        item _: VaultItem.Payload,
        metadata _: VaultItem.Metadata,
        behaviour _: VaultItemViewBehaviour,
    ) -> some View {
        Text("Code")
    }

    func clearViewCache() async {
        // noop
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        // noop
    }

    func didAppear() {
        // noop
    }
}
