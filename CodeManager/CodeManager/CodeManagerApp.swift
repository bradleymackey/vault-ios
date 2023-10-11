//
//  CodeManagerApp.swift
//  CodeManager
//
//  Created by Bradley Mackey on 05/05/2023.
//

import OTPFeed
import OTPFeediOS
import VaultSettings
import SwiftUI
import VaultCore

@MainActor
@main
struct CodeManagerApp: App {
    @State private var feedViewModel: FeedViewModel<InMemoryVaultStore>
    @State private var totpPreviewGenerator: TOTPPreviewViewGenerator<RealTOTPPreviewViewFactory>
    @State private var hotpPreviewGenerator: HOTPPreviewViewGenerator<RealHOTPPreviewViewFactory>
    @State private var pasteboard = Pasteboard(LiveSystemPasteboard())
    @State private var localSettings: LocalSettings
    @State private var settingsViewModel = SettingsViewModel()
    @State private var clock: EpochClock
    @State private var isShowingCopyPaste = false

    private let toastOptions = SimpleToastOptions(
        hideAfter: 1.5,
        animation: .spring,
        modifierType: .slide
    )

    init() {
        let defaults = Defaults(userDefaults: .standard)
        let localSettings = LocalSettings(defaults: defaults)
        let timer = LiveIntervalTimer()
        let clock = EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 })
        let store = InMemoryVaultStore(codes: [
            DemoCodeFactory.totpCode(issuer: "I1"),
            DemoCodeFactory.totpCode(issuer: "Cloudflare"),
            DemoCodeFactory.hotpCode(issuer: "Tommy Tobes"),
            DemoCodeFactory.hotpCode(issuer: "Ranner"),
        ])
        let totp = TOTPPreviewViewGenerator(
            viewFactory: RealTOTPPreviewViewFactory(),
            updaterFactory: CodeTimerControllerFactory(timer: timer, clock: clock),
            clock: clock,
            timer: timer
        )
        let hotp = HOTPPreviewViewGenerator(
            viewFactory: RealHOTPPreviewViewFactory(),
            timer: timer
        )
        let feed = FeedViewModel(store: store, caches: [totp, hotp])

        _clock = State(wrappedValue: clock)
        _feedViewModel = State(wrappedValue: feed)
        _totpPreviewGenerator = State(wrappedValue: totp)
        _hotpPreviewGenerator = State(wrappedValue: hotp)
        _localSettings = State(wrappedValue: localSettings)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    CodeListView(
                        feedViewModel: feedViewModel,
                        localSettings: localSettings,
                        viewGenerator: GenericVaultItemPreviewViewGenerator(
                            totpGenerator: totpPreviewGenerator,
                            hotpGenerator: hotpPreviewGenerator
                        )
                    )
                    .environment(pasteboard)
                    .environment(clock)
                }
                .tabItem {
                    Label(feedViewModel.title, systemImage: "key.horizontal.fill")
                }

                NavigationStack {
                    CodeAddView()
                }
                .tabItem {
                    Label("Add", systemImage: "plus")
                }

                NavigationStack {
                    CodeSettingsView(viewModel: settingsViewModel, localSettings: localSettings)
                }
                .tabItem {
                    Label(settingsViewModel.title, systemImage: "gear")
                }
            }
            .onReceive(pasteboard.didPaste()) {
                isShowingCopyPaste = true
            }
            .simpleToast(isPresented: $isShowingCopyPaste, options: toastOptions) {
                ToastAlertMessageView.copiedToClipboard()
                    .padding(.top, 24)
            }
        }
    }
}
