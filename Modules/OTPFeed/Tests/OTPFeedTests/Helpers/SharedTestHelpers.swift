import Foundation
import OTPCore
import OTPFeed

func anyNSError() -> NSError {
    NSError(domain: "any", code: 100)
}

func uniqueCode() -> OTPAuthCode {
    let randomData = Data.random(count: 50)
    return OTPAuthCode(secret: .init(data: randomData, format: .base32), accountName: "Some Account")
}

func uniqueStoredCode() -> StoredOTPCode {
    StoredOTPCode(id: UUID(), code: uniqueCode())
}
