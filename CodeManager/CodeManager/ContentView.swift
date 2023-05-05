//
//  ContentView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 05/05/2023.
//

import SwiftUI
import OTPFeediOS
import OTPFeed
import OTPCore

struct ContentView: View {
    var body: some View {
        OTPCodeFeedView(
            viewModel: .init(store: MockCodeStore()),
            clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
            timer: LiveIntervalTimer()
        )
    }
}

struct MockCodeStore: OTPCodeStoreReader {
    let codes: [StoredOTPCode] = [
        .init(id: UUID(), code: .init(secret: .empty(), accountName: "Test 1")),
        .init(id: UUID(), code: .init(secret: .empty(), accountName: "Test 2")),
        .init(id: UUID(), code: .init(secret: .empty(), accountName: "Test 3")),
    ]

    func retrieve() async throws -> [OTPFeed.StoredOTPCode] {
        codes
    }
}
