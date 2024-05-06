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
    @State private var creatingItem: CreatingItem?
    @Environment(\.scenePhase) private var scenePhase

    enum Modal: Identifiable {
        case addItem
        case detail(UUID, StoredVaultItem)
        case creatingItem(CreatingItem)

        var id: some Hashable {
            switch self {
            case .addItem: "add"
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
                Button {
                    modal = .addItem
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(isEditing)
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
            case .addItem:
                NavigationStack {
                    CodeAddView(creatingItem: $creatingItem)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
        .onChange(of: creatingItem) { _, newValue in
            if let newValue {
                modal = .creatingItem(newValue)
                creatingItem = nil // reset so we can detect further changes
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
