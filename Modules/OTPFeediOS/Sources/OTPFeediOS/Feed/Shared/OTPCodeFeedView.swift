import CryptoEngine
import OTPFeed
import OTPSettings
import SwiftUI
import VaultCore

@MainActor
public struct OTPCodeFeedView<
    Store: VaultStore,
    ViewGenerator: VaultItemPreviewViewGenerator
>: View where
    ViewGenerator.VaultItem == GenericOTPAuthCode
{
    public var viewModel: FeedViewModel<Store>
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
            if viewModel.codes.isEmpty {
                noCodesView
            } else {
                listOfCodesView
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }

    private var noCodesView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "key.viewfinder")
                .font(.largeTitle)
            Text(localized(key: "codeFeed.noCodes.title"))
                .font(.headline.bold())
        }
        .foregroundColor(.secondary)
        .padding()
    }

    private var reorderingBehaviour: VaultItemViewBehaviour {
        .obfuscate(message: nil)
    }

    private var currentBehaviour: VaultItemViewBehaviour {
        if isEditing {
            return .obfuscate(message: localized(key: "action.tapToView"))
        } else if isReordering {
            return reorderingBehaviour
        } else {
            return .normal
        }
    }

    private var listOfCodesView: some View {
        ScrollView {
            LazyVGrid(columns: columns, content: {
                ReorderableForEach(items: viewModel.codes, isDragging: $isReordering, isEnabled: isEditing) { code in
                    viewGenerator.makeVaultPreviewView(id: code.id, code: code.code, behaviour: currentBehaviour)
                } previewContent: { code in
                    viewGenerator.makeVaultPreviewView(id: code.id, code: code.code, behaviour: reorderingBehaviour)
                } moveAction: { from, to in
                    viewModel.codes.move(fromOffsets: from, toOffset: to)
                }
            })
            .padding()
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: minimumGridSize), spacing: gridSpacing, alignment: .top)]
    }

    private var minimumGridSize: Double {
        switch localSettings.state.previewSize {
        case .medium:
            return 150
        case .large:
            return 250
        }
    }
}

struct OTPCodeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeFeedView(
            viewModel: .init(store: InMemoryVaultStore(codes: [
                .init(
                    id: UUID(),
                    created: Date(),
                    updated: Date(),
                    userDescription: "My Cool Code",
                    code: .init(
                        type: .totp(),
                        data: .init(
                            secret: .empty(),
                            accountName: "example@example.com",
                            issuer: "i"
                        )
                    )
                ),
            ])),
            localSettings: .init(defaults: .init(userDefaults: .standard)),
            viewGenerator: GenericGenerator(),
            isEditing: .constant(false)
        )
    }

    struct GenericGenerator: VaultItemPreviewViewGenerator {
        func makeVaultPreviewView(
            id _: UUID,
            code _: GenericOTPAuthCode,
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
