//
//  ContentView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 05/05/2023.
//

import OTPCore
import OTPFeed
import OTPFeediOS
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            OTPCodeFeedView(
                viewModel: .init(store: MockCodeStore()),
                totpGenerator: LiveTOTPViewGenerator(
                    clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
                    timer: LiveIntervalTimer()
                ),
                hotpGenerator: LiveHOTPViewGenerator(),
                gridSpacing: 8,
                contentPadding: .init(top: 8, leading: 16, bottom: 16, trailing: 16)
            )
            .navigationTitle(Text("Codes"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct MockCodeStore: OTPCodeStoreReader {
    let codes: [StoredOTPCode] = [
        .init(id: UUID(), code: .init(secret: .empty(), accountName: "example@example.com", issuer: "Ebay")),
        .init(id: UUID(), code: .init(secret: .empty(), accountName: "example@example.com", issuer: "Cloudflare")),
        .init(id: UUID(), code: .init(type: .hotp(), secret: .empty(), accountName: "HOTP test", issuer: "Authority")),
    ]

    func retrieve() async throws -> [OTPFeed.StoredOTPCode] {
        codes
    }
}
