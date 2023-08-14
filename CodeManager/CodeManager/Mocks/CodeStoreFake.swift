//
//  CodeStoreFake.swift
//  CodeManager
//
//  Created by Bradley Mackey on 07/05/2023.
//

import Foundation
import OTPFeed

struct CodeStoreFake: OTPCodeStoreReader {
    static func totpCode() -> StoredOTPCode {
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "My Cool Code",
            code: .init(type: .totp(), secret: .empty(), accountName: "example@example.com", issuer: "Ebay")
        )
    }

    static func hotpCode() -> StoredOTPCode {
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "My Other Cool code",
            code: .init(type: .hotp(), secret: .empty(), accountName: "HOTP test", issuer: "Authority")
        )
    }

    static let codes: [StoredOTPCode] = {
        var result = [StoredOTPCode]()
        for _ in 0 ..< 50 {
            result.append(totpCode())
        }
        for _ in 0 ..< 50 {
            result.append(hotpCode())
        }
        return result
    }()

    func retrieve() async throws -> [OTPFeed.StoredOTPCode] {
        Self.codes
    }
}
