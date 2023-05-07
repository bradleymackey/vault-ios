//
//  MockCodeStore.swift
//  CodeManager
//
//  Created by Bradley Mackey on 07/05/2023.
//

import Foundation
import OTPFeed

#if DEBUG
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
#endif
