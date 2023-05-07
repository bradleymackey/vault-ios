//
//  CodeManagerApp.swift
//  CodeManager
//
//  Created by Bradley Mackey on 05/05/2023.
//

import OTPFeed
import SwiftUI

@main
struct CodeManagerApp: App {
    @StateObject var feedViewModel = FeedViewModel(store: MockCodeStore())

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(feedViewModel: feedViewModel)
                    .tabItem {
                        Label(feedViewModel.title, systemImage: "key.horizontal.fill")
                    }
            }
        }
    }
}
