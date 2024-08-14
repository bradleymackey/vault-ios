import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

/// Entrypoint scene for the vault app.
@MainActor
public struct VaultMainScene: Scene {
    @State private var totpPreviewGenerator: TOTPPreviewViewGenerator<TOTPPreviewViewFactoryImpl>
    @State private var hotpPreviewGenerator: HOTPPreviewViewGenerator<HOTPPreviewViewFactoryImpl>
    @State private var notePreviewGenerator: SecureNotePreviewViewGenerator<SecureNotePreviewViewFactoryImpl>
    @State private var pasteboard: Pasteboard
    @State private var localSettings: LocalSettings
    @State private var settingsViewModel = SettingsViewModel()
    @State private var clock: EpochClock
    @State private var isShowingCopyPaste = false
    @State private var backupStore = BackupPasswordStoreImpl(
        secureStorage: SecureStorageImpl(keychain: .default),
        authenticationPolicy: .default
    )
    @State private var deviceAuthenticationService = DeviceAuthenticationService(policy: .default)
    @State private var vaultDataModel: VaultDataModel

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
        let pasteboard = Pasteboard(SystemPasteboardImpl(clock: clock), localSettings: localSettings)
        let vaultDataModel = VaultDataModel(
            vaultStore: store,
            vaultTagStore: store,
            itemCaches: [totp, hotp]
        )

        _pasteboard = State(wrappedValue: pasteboard)
        _clock = State(wrappedValue: clock)
        _totpPreviewGenerator = State(wrappedValue: totp)
        _hotpPreviewGenerator = State(wrappedValue: hotp)
        _notePreviewGenerator = State(wrappedValue: note)
        _localSettings = State(wrappedValue: localSettings)
        _vaultDataModel = State(wrappedValue: vaultDataModel)
    }

    public var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    VaultListView(
                        localSettings: localSettings,
                        viewGenerator: GenericVaultItemPreviewViewGenerator(
                            totpGenerator: totpPreviewGenerator,
                            hotpGenerator: hotpPreviewGenerator,
                            noteGenerator: notePreviewGenerator
                        )
                    )
                }
                .tabItem {
                    Label("Vault", systemImage: "key.horizontal.fill")
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
            .environment(pasteboard)
            .environment(clock)
            .environment(deviceAuthenticationService)
            .environment(vaultDataModel)
        }
    }
}
