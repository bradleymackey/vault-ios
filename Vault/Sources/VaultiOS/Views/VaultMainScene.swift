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
    @State private var deviceAuthenticationService = DeviceAuthenticationService(policy: .default)
    @State private var vaultDataModel: VaultDataModel
    @State private var selectedView: SidebarItem? = .items

    enum SidebarItem: Hashable {
        case items
        case backups
        case restoreBackup
        case settings
    }

    @Environment(\.scenePhase) private var scenePhase

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
        let backupStore = BackupPasswordStoreImpl(
            secureStorage: SecureStorageImpl(keychain: .default)
        )
        let vaultDataModel = VaultDataModel(
            vaultStore: store,
            vaultTagStore: store,
            backupPasswordStore: backupStore,
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
            NavigationSplitView {
                List(selection: $selectedView) {
                    Section {
                        NavigationLink(value: SidebarItem.items) {
                            Label("Items", systemImage: "key.horizontal.fill")
                        }
                    }

                    Section {
                        NavigationLink(value: SidebarItem.backups) {
                            Label("Backups", systemImage: "doc.on.doc.fill")
                        }

                        NavigationLink(value: SidebarItem.restoreBackup) {
                            Label("Restore Backup", systemImage: "square.and.arrow.down.fill")
                        }
                    }

                    Section {
                        NavigationLink(value: SidebarItem.settings) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
                .navigationTitle("Vault")
                .listStyle(.sidebar)
            } detail: {
                // Show the selected view in the detail area
                switch selectedView {
                case .items:
                    VaultListView(
                        localSettings: localSettings,
                        viewGenerator: GenericVaultItemPreviewViewGenerator(
                            totpGenerator: totpPreviewGenerator,
                            hotpGenerator: hotpPreviewGenerator,
                            noteGenerator: notePreviewGenerator
                        )
                    )
                case .settings:
                    NavigationStack {
                        VaultSettingsView(viewModel: settingsViewModel, localSettings: localSettings)
                    }
                case .backups:
                    NavigationStack {
                        BackupView()
                    }
                case .restoreBackup:
                    NavigationStack {
                        RestoreBackupView()
                    }
                case .none:
                    Text("Select an option from the sidebar")
                }
            }
            .onReceive(pasteboard.didPaste()) {
                isShowingCopyPaste = true
            }
            .simpleToast(isPresented: $isShowingCopyPaste, options: toastOptions, onDismiss: nil) {
                ToastAlertMessageView.copiedToClipboard()
                    .padding(.top, 24)
            }
            .environment(pasteboard)
            .environment(clock)
            .environment(deviceAuthenticationService)
            .environment(vaultDataModel)
        }
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .background:
                vaultDataModel.purgeSensitiveData()
            case .active, .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
