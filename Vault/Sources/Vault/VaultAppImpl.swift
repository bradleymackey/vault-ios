import SwiftUI
import VaultCore
import VaultFeed
import VaultFeediOS
import VaultSettings

/// Entrypoint scene for the vault app.
@MainActor
public struct VaultMainScene: Scene {
    @State private var feedViewModel: FeedViewModel<InMemoryVaultStore>
    @State private var totpPreviewGenerator: TOTPPreviewViewGenerator<RealTOTPPreviewViewFactory>
    @State private var hotpPreviewGenerator: HOTPPreviewViewGenerator<RealHOTPPreviewViewFactory>
    @State private var notePreviewGenerator: SecureNotePreviewViewGenerator<RealSecureNotePreviewViewFactory>
    @State private var pasteboard: Pasteboard
    @State private var localSettings: LocalSettings
    @State private var settingsViewModel = SettingsViewModel()
    @State private var clock: EpochClock
    @State private var isShowingCopyPaste = false

    private let toastOptions = SimpleToastOptions(
        hideAfter: 1.5,
        animation: .spring,
        modifierType: .slide
    )

    public init() {
        let defaults = Defaults(userDefaults: .standard)
        let localSettings = LocalSettings(defaults: defaults)
        let timer = LiveIntervalTimer()
        let clock = EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 })
        let store = InMemoryVaultStore(codes: [
            DemoVaultFactory.totpCode(issuer: "Ebay"),
            DemoVaultFactory.totpCode(issuer: "Cloudflare"),
            DemoVaultFactory.hotpCode(issuer: "Cool Company"),
            DemoVaultFactory.hotpCode(issuer: "Other Company"),
            DemoVaultFactory.secureNote(title: "Secure Note 1", contents: "This is the contents..."),
        ])
        let totp = TOTPPreviewViewGenerator(
            viewFactory: RealTOTPPreviewViewFactory(),
            updaterFactory: OTPCodeTimerControllerFactory(timer: timer, clock: clock),
            clock: clock,
            timer: timer
        )
        let hotp = HOTPPreviewViewGenerator(
            viewFactory: RealHOTPPreviewViewFactory(),
            timer: timer
        )
        let note = SecureNotePreviewViewGenerator(viewFactory: RealSecureNotePreviewViewFactory())
        let feed = FeedViewModel(store: store, caches: [totp, hotp])
        let pasteboard = Pasteboard(LiveSystemPasteboard(clock: clock), localSettings: localSettings)

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
        }
    }
}
