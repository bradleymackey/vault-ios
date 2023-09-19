//
//  CodeManagerApp.swift
//  CodeManager
//
//  Created by Bradley Mackey on 05/05/2023.
//

import OTPCore
import OTPFeed
import OTPFeediOS
import OTPSettings
import SwiftUI

@main
struct CodeManagerApp: App {
    @StateObject private var feedViewModel: FeedViewModel<InMemoryCodeStore>
    @StateObject private var totpPreviewGenerator: TOTPPreviewViewGenerator<RealTOTPPreviewViewFactory>
    @StateObject private var hotpPreviewGenerator: HOTPPreviewViewGenerator<RealHOTPPreviewViewFactory>
    @StateObject private var pasteboard = Pasteboard(LiveSystemPasteboard())
    @StateObject private var localSettings: LocalSettings
    @State private var isShowingCopyPaste = false

    init() {
        let defaults = Defaults(userDefaults: .standard)
        let localSettings = LocalSettings(defaults: defaults)
        let timer = LiveIntervalTimer()
        let clock = EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 })
        let store = InMemoryCodeStore(codes: [
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

        _feedViewModel = StateObject(wrappedValue: feed)
        _totpPreviewGenerator = StateObject(wrappedValue: totp)
        _hotpPreviewGenerator = StateObject(wrappedValue: hotp)
        _localSettings = StateObject(wrappedValue: localSettings)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    CodeListView(
                        feedViewModel: feedViewModel,
                        viewGenerator: GenericOTPViewGenerator(
                            totpGenerator: totpPreviewGenerator,
                            hotpGenerator: hotpPreviewGenerator
                        )
                    )
                    .environmentObject(pasteboard)
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
                    CodeSettingsView(localSettings: localSettings)
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
            .onReceive(pasteboard.objectWillChange) {
                isShowingCopyPaste = true
            }
            .toast(isPresenting: $isShowingCopyPaste, offsetY: 20) {
                .copiedToClipboard()
            }
        }
    }
}
