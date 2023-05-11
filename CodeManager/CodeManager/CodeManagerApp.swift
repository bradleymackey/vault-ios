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
    @StateObject var feedViewModel = FeedViewModel(store: MockCodeStore())

    let totpGenerator = TOTPPreviewViewGenerator(
        clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
        timer: LiveIntervalTimer(),
        hideCodes: false
    )

    var body: some Scene {
        WindowGroup {
            TabView {
                CodeListView(feedViewModel: feedViewModel, generator: totpGenerator)
                    .tabItem {
                        Label(feedViewModel.title, systemImage: "key.horizontal.fill")
                    }
            }
        }
    }
}
