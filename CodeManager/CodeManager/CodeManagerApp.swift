//
//  CodeManagerApp.swift
//  CodeManager
//
//  Created by Bradley Mackey on 05/05/2023.
//

import OTPCore
import OTPFeed
import OTPFeediOS
import SwiftUI

@main
struct CodeManagerApp: App {
    @StateObject private var feedViewModel: FeedViewModel<InMemoryCodeStore>
    @StateObject private var totpPreviewGenerator: TOTPPreviewViewGenerator<RealTOTPPreviewViewFactory>
    @StateObject private var hotpPreviewGenerator: HOTPPreviewViewGenerator
    @StateObject private var pasteboard = Pasteboard(LiveSystemPasteboard())
    @State private var isShowingCopyPaste = false

    init() {
        let store = InMemoryCodeStore(codes: [
            DemoCodeFactory.totpCode(issuer: "I1"),
            DemoCodeFactory.totpCode(issuer: "Cloudflare"),
            DemoCodeFactory.hotpCode(issuer: "Tommy Tobes"),
            DemoCodeFactory.hotpCode(issuer: "Ranner"),
        ])
        let totp = TOTPPreviewViewGenerator(
            viewFactory: RealTOTPPreviewViewFactory(),
            clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
            timer: LiveIntervalTimer()
        )
        let hotp = HOTPPreviewViewGenerator(timer: LiveIntervalTimer())
        let feed = FeedViewModel(store: store, caches: [totp, hotp])

        _totpPreviewGenerator = StateObject(wrappedValue: totp)
        _hotpPreviewGenerator = StateObject(wrappedValue: hotp)
        _feedViewModel = StateObject(wrappedValue: feed)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    CodeListView(
                        feedViewModel: feedViewModel,
                        totpPreviewGenerator: totpPreviewGenerator,
                        hotpPreviewGenerator: hotpPreviewGenerator
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
                    CodeSettingsView()
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
