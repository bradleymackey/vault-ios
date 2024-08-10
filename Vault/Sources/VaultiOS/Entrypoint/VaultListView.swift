import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

@MainActor
struct VaultListView<
    Store: VaultStore & VaultTagStore,
    Generator: VaultItemPreviewViewGenerator & VaultItemPreviewActionHandler & VaultItemCopyActionHandler
>: View
    where Generator.PreviewItem == VaultItem.Payload
{
    var feedViewModel: FeedViewModel<Store>
    var localSettings: LocalSettings
    var viewGenerator: Generator

    @Environment(Pasteboard.self) var pasteboard: Pasteboard
    @State private var isEditing = false
    @State private var modal: Modal?
    @State private var navigationPath = NavigationPath()
    @Environment(\.scenePhase) private var scenePhase

    enum Modal: Hashable, IdentifiableSelf {
        case detail(Identifier<VaultItem>, VaultItem)
        case creatingItem(CreatingItem)
        case tags
    }

    var body: some View {
        VaultItemFeedView(
            viewModel: feedViewModel,
            localSettings: localSettings,
            viewGenerator: interactableViewGenerator(),
            isEditing: $isEditing,
            gridSpacing: 12
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    modal = .tags
                } label: {
                    Label("Tags", systemImage: "tag.fill")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        modal = .creatingItem(.otpCode)
                    } label: {
                        LabeledContent {
                            Text(feedViewModel.createCodeTitle)
                        } label: {
                            Image(systemName: "qrcode")
                        }
                    }

                    Button {
                        modal = .creatingItem(.secureNote)
                    } label: {
                        LabeledContent {
                            Text(feedViewModel.createNoteTitle)
                        } label: {
                            Image(systemName: "text.alignleft")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }

            if !feedViewModel.codes.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? feedViewModel.doneEditingTitle : feedViewModel.editTitle)
                            .fontWeight(isEditing ? .semibold : .regular)
                            .animation(.none)
                    }
                }
            }
        }
        .sheet(item: $modal, onDismiss: nil) { visible in
            switch visible {
            case let .detail(_, storedCode):
                NavigationStack(path: $navigationPath) {
                    VaultDetailEditView(
                        feedViewModel: feedViewModel,
                        storedItem: storedCode,
                        previewGenerator: viewGenerator,
                        openInEditMode: isEditing,
                        navigationPath: $navigationPath
                    )
                }
            case let .creatingItem(creatingItem):
                NavigationStack(path: $navigationPath) {
                    VaultDetailCreateView(
                        feedViewModel: feedViewModel,
                        creatingItem: creatingItem,
                        previewGenerator: viewGenerator,
                        navigationPath: $navigationPath
                    )
                }
            case .tags:
                NavigationStack {
                    VaultTagFeedView(viewModel: .init(store: feedViewModel.store))
                }
            }
        }
        .onChange(of: modal) { _, newValue in
            // When the detail modal is dismissed, exit editing mode.
            if newValue == nil { isEditing = false }
        }
        .onChange(of: scenePhase) { _, newValue in
            viewGenerator.scenePhaseDidChange(to: newValue)
        }
        .onAppear {
            viewGenerator.didAppear()
        }
    }

    func interactableViewGenerator()
        -> VaultItemOnTapDecoratorViewGenerator<Generator>
    {
        VaultItemOnTapDecoratorViewGenerator(generator: viewGenerator) { id in
            if isEditing {
                guard let item = feedViewModel.code(id: id) else { return }
                modal = .detail(id, item)
            } else if let previewAction = viewGenerator.previewActionForVaultItem(id: id) {
                switch previewAction {
                case let .copyText(text):
                    pasteboard.copy(text)
                case let .openItemDetail(id):
                    guard let item = feedViewModel.code(id: id) else { return }
                    modal = .detail(id, item)
                }
            }
        }
    }
}
