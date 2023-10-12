import SwiftUI
import VaultCore
import VaultFeed
import VaultFeediOS
import VaultSettings

@MainActor
struct VaultListView<Store: VaultStore, Generator: VaultItemPreviewViewGenerator & VaultItemCopyTextProvider>: View
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
        case addItem
        case detail(UUID, StoredVaultItem)

        var id: some Hashable {
            switch self {
            case .addItem:
                return "add"
            case let .detail(id, _):
                return id.uuidString
            }
        }
    }

    var body: some View {
        OTPCodeFeedView(
            viewModel: feedViewModel,
            localSettings: localSettings,
            viewGenerator: interactableViewGenerator(),
            isEditing: $isEditing,
            gridSpacing: 12
        )
        .navigationTitle(Text(feedViewModel.title))
        .navigationBarTitleDisplayMode(.large)
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
        .sheet(item: $modal) { visible in
            switch visible {
            case .addItem:
                CodeAddView()
            case let .detail(_, storedCode):
                NavigationView {
                    VaultDetailView(feedViewModel: feedViewModel, storedCode: storedCode)
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
        -> OTPOnTapDecoratorViewGenerator<Generator>
    {
        OTPOnTapDecoratorViewGenerator(generator: viewGenerator) { id in
            if isEditing {
                guard let code = feedViewModel.code(id: id) else { return }
                modal = .detail(id, code)
            } else if let code = viewGenerator.currentCopyableText(id: id) {
                pasteboard.copy(code)
            }
        }
    }
}
