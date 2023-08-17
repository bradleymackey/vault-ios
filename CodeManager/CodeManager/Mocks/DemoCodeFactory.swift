//
//  DemoCodeFactory.swift
//  CodeManager
//
//  Created by Bradley Mackey on 07/05/2023.
//

import Foundation
import OTPFeed

enum DemoCodeFactory {
    static func totpCode(issuer: String = "Ebay") -> StoredOTPCode {
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "My Cool Code",
            code: .init(
                type: .totp(),
                data: .init(
                    secret: .empty(),
                    accountName: "example@example.com",
                    issuer: issuer
                )
            )
        )
    }

    static func hotpCode(issuer: String = "Ebay") -> StoredOTPCode {
        .init(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: "My Other Cool code",
            code: .init(
                type: .hotp(),
                data: .init(
                    secret: .empty(),
                    accountName: "HOTP test",
                    issuer: issuer
                )
            )
        )
    }
}
