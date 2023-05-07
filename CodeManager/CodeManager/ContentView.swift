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

@MainActor
struct ContentView: View {
    @StateObject private var feedViewModel = FeedViewModel(store: MockCodeStore())
    @State private var isEditing = false
    @State private var modal: Modal?

    enum Modal: Identifiable {
        case detail(UUID, OTPAuthCode)

        var id: some Hashable {
            switch self {
            case let .detail(id, _):
                return id
            }
        }
    }

    var body: some View {
        NavigationView {
            OTPCodeFeedView(
                viewModel: feedViewModel,
                totpGenerator: totpGenerator(hideCodes: isEditing),
                hotpGenerator: hotpGenerator(hideCodes: isEditing),
                gridSpacing: 24,
                contentPadding: .init(top: 8, leading: 16, bottom: 16, trailing: 16)
            )
            .navigationTitle(Text("Codes"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing.toggle()
                        }
                    } label: {
                        Text("Edit")
                    }
                }
            }
            .sheet(item: $modal) { visible in
                switch visible {
                case let .detail(_, code):
                    switch code.type {
                    case let .totp(period):
                        NavigationView {
                            OTPCodeDetailView(
                                preview: totpGenerator(hideCodes: false).makeTOTPView(period: period, code: code),
                                viewModel: .init(code: code)
                            )
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button {
                                        modal = nil
                                    } label: {
                                        Text("Done")
                                    }
                                }
                            }
                        }
                    case let .hotp(counter):
                        NavigationView {
                            OTPCodeDetailView(
                                preview: hotpGenerator(hideCodes: false).makeHOTPView(counter: counter, code: code),
                                viewModel: .init(code: code)
                            )
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button {
                                        modal = nil
                                    } label: {
                                        Text("Done")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func totpGenerator(hideCodes: Bool) -> some TOTPViewGenerator {
        LiveTOTPPreviewViewGenerator(
            clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
            timer: LiveIntervalTimer(),
            hideCodes: hideCodes
        )
    }

    func hotpGenerator(hideCodes: Bool) -> some HOTPViewGenerator {
        LiveHOTPPreviewViewGenerator(hideCodes: hideCodes)
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
