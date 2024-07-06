import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

/// Entrypoint scene for the vault app.
@MainActor
public struct VaultMainScene: Scene {
    @State private var feedViewModel: FeedViewModel<PersistedLocalVaultStore>
    @State private var totpPreviewGenerator: TOTPPreviewViewGenerator<TOTPPreviewViewFactoryImpl>
    @State private var hotpPreviewGenerator: HOTPPreviewViewGenerator<HOTPPreviewViewFactoryImpl>
    @State private var notePreviewGenerator: SecureNotePreviewViewGenerator<SecureNotePreviewViewFactoryImpl>
    @State private var pasteboard: Pasteboard
    @State private var localSettings: LocalSettings
    @State private var settingsViewModel = SettingsViewModel()
    @State private var clock: EpochClock
    @State private var isShowingCopyPaste = false
    @State private var backupStore = BackupPasswordStoreImpl(keychain: .init(accessGroup: .default))

    private let toastOptions = SimpleToastOptions(
        hideAfter: 1.5,
        animation: .spring,
        modifierType: .slide
    )

    public init() {
        let defaults = Defaults(userDefaults: .standard)
        let localSettings = LocalSettings(defaults: defaults)
        let timer = IntervalTimerImpl()
        let clock = EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 })
        let storeFactory = PersistedLocalVaultStoreFactory(fileManager: .default)
        let store = storeFactory.makeVaultStore()
        let totp = TOTPPreviewViewGenerator(
            viewFactory: TOTPPreviewViewFactoryImpl(),
            updaterFactory: OTPCodeTimerUpdaterFactoryImpl(timer: timer, clock: clock),
            clock: clock,
            timer: timer
        )
        let hotp = HOTPPreviewViewGenerator(
            viewFactory: HOTPPreviewViewFactoryImpl(),
            timer: timer
        )
        let note = SecureNotePreviewViewGenerator(viewFactory: SecureNotePreviewViewFactoryImpl())
        let feed = FeedViewModel(store: store, caches: [totp, hotp])
        let pasteboard = Pasteboard(SystemPasteboardImpl(clock: clock), localSettings: localSettings)

        _pasteboard = State(wrappedValue: pasteboard)
        _clock = State(wrappedValue: clock)
        _feedViewModel = State(wrappedValue: feed)
        _totpPreviewGenerator = State(wrappedValue: totp)
        _hotpPreviewGenerator = State(wrappedValue: hotp)
        _notePreviewGenerator = State(wrappedValue: note)
        _localSettings = State(wrappedValue: localSettings)
    }

    public var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    VaultListView(
                        feedViewModel: feedViewModel,
                        localSettings: localSettings,
                        viewGenerator: GenericVaultItemPreviewViewGenerator(
                            totpGenerator: totpPreviewGenerator,
                            hotpGenerator: hotpPreviewGenerator,
                            noteGenerator: notePreviewGenerator
                        )
                    )
                    .environment(pasteboard)
                    .environment(clock)
                }
                .tabItem {
                    Label(feedViewModel.title, systemImage: "key.horizontal.fill")
                }

                NavigationStack {
                    VaultSettingsView(viewModel: settingsViewModel, localSettings: localSettings)
                }
                .tabItem {
                    Label(settingsViewModel.title, systemImage: "gear")
                }
            }
            .onReceive(pasteboard.didPaste()) {
                isShowingCopyPaste = true
            }
            .simpleToast(isPresented: $isShowingCopyPaste, options: toastOptions, onDismiss: nil) {
                ToastAlertMessageView.copiedToClipboard()
                    .padding(.top, 24)
            }
            .environment(backupStore)
        }
    }
}
