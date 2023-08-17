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
    @StateObject private var feedViewModel = FeedViewModel(store: InMemoryCodeStore(codes: [
        DemoCodeFactory.totpCode(issuer: "I1"),
        DemoCodeFactory.totpCode(issuer: "Cloudflare"),
        DemoCodeFactory.hotpCode(issuer: "Tommy Tobes"),
        DemoCodeFactory.hotpCode(issuer: "Ranner"),
    ]))
    @StateObject private var totpPreviewGenerator = TOTPPreviewViewGenerator(
        clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
        timer: LiveIntervalTimer()
    )
    @StateObject private var hotpPreviewGenerator = HOTPPreviewViewGenerator(timer: LiveIntervalTimer())
    @StateObject private var pasteboard = Pasteboard(LiveSystemPasteboard())
    @State private var isShowingCopyPaste = false

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
