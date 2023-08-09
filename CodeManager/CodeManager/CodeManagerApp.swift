//
//  CodeManagerApp.swift
//  CodeManager
//
//  Created by Bradley Mackey on 05/05/2023.
//

import OTPCore
import OTPFeed
import SwiftUI

@main
struct CodeManagerApp: App {
    @StateObject var feedViewModel = FeedViewModel(store: CodeStoreFake())
    @StateObject var intervalTimer = LiveIntervalTimer()
    @StateObject var epochClock = EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 })

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    CodeListView(feedViewModel: feedViewModel)
                        .environmentObject(intervalTimer)
                        .environmentObject(epochClock)
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
        }
    }
}
