import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

@MainActor
struct VaultListView<
    Store: VaultStore,
    Generator: VaultItemPreviewViewGenerator & VaultItemPreviewActionHandler & VaultItemCopyActionHandler
>: View
    where Generator.PreviewItem == VaultItem
{
    var feedViewModel: FeedViewModel<Store>
    var localSettings: LocalSettings
    var viewGenerator: Generator

    @Environment(Pasteboard.self) var pasteboard: Pasteboard
    @State private var isEditing = false
    @State private var modal: Modal?
    @Environment(\.scenePhase) private var scenePhase

    enum Modal: Identifiable {
        case detail(UUID, StoredVaultItem)
        case creatingItem(CreatingItem)

        var id: some Hashable {
            switch self {
            case let .creatingItem(item): "creating" + String(item.hashValue)
            case let .detail(id, _): id.uuidString
            }
        }
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
                NavigationStack {
                    VaultDetailEditView(
                        feedViewModel: feedViewModel,
                        storedItem: storedCode,
                        previewGenerator: viewGenerator
                    )
                }
            case let .creatingItem(creatingItem):
                NavigationStack {
                    VaultDetailCreateView(
                        feedViewModel: feedViewModel,
                        creatingItem: creatingItem,
                        previewGenerator: viewGenerator
                    )
                }
            }
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
