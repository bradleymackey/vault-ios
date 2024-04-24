import CryptoEngine
import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

@MainActor
public struct VaultItemFeedView<
    Store: VaultStore,
    ViewGenerator: VaultItemPreviewViewGenerator
>: View where
    ViewGenerator.PreviewItem == VaultItem
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
    }

    private var noCodesFoundView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "key.viewfinder")
                .font(.largeTitle)
            Text(localized(key: "codeFeed.noCodes.title"))
                .font(.headline.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .modifier(OTPCardViewModifier())
        .foregroundStyle(.secondary)
    }

    private var reorderingBehaviour: VaultItemViewBehaviour {
        .obfuscate(message: nil)
    }

    private var currentBehaviour: VaultItemViewBehaviour {
        if isEditing {
            .obfuscate(message: localized(key: "action.tapToView"))
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
                    SearchTextField(title: viewModel.searchCodesPromptTitle, text: $viewModel.searchQuery)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
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
            viewModel.codes.move(fromOffsets: from, toOffset: to)
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: gridSpacing, alignment: .top)]
    }
}

struct VaultItemFeedView_Previews: PreviewProvider {
    static var previews: some View {
        VaultItemFeedView(
            viewModel: .init(store: InMemoryVaultStore(codes: [
                .init(
                    metadata: .init(
                        id: UUID(),
                        created: Date(),
                        updated: Date(),
                        userDescription: "My Cool Code"
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
            ])),
            localSettings: .init(defaults: .init(userDefaults: .standard)),
            viewGenerator: GenericGenerator(),
            isEditing: .constant(false)
        )
    }

    struct GenericGenerator: VaultItemPreviewViewGenerator {
        func makeVaultPreviewView(
            item _: VaultItem,
            metadata _: StoredVaultItem.Metadata,
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
