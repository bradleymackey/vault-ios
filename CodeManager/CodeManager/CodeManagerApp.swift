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
    @StateObject var feedViewModel = FeedViewModel(store: CodeStoreFake())
    @StateObject private var totpPreviewGenerator = TOTPPreviewViewGenerator(
        clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
        timer: LiveIntervalTimer()
    )
    @StateObject private var hotpPreviewGenerator = HOTPPreviewViewGenerator(timer: LiveIntervalTimer())
    @State private var isShowingCopyPaste = false

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    CodeListView(
                        feedViewModel: feedViewModel,
                        totpPreviewGenerator: totpPreviewGenerator,
                        hotpPreviewGenerator: hotpPreviewGenerator,
                        isShowingCopyPaste: $isShowingCopyPaste
                    )
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
            .toast(isPresenting: $isShowingCopyPaste, offsetY: 20) {
                .copiedToClipboard()
            }
        }
    }
}
