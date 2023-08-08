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
    @StateObject var feedViewModel = FeedViewModel(store: CodeStoreFake())

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    CodeListView(feedViewModel: feedViewModel)
                }
                .tabItem {
                    Label(feedViewModel.title, systemImage: "key.horizontal.fill")
                }
            }
        }
    }
}
