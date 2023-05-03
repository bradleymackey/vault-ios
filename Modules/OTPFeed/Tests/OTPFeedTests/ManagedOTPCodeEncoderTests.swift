import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

final class ManagedOTPCodeEncoderTests: XCTestCase {
    func test_encodeDigits_encodesToNSNumber() {
        let samples: [OTPAuthDigits: NSNumber] = [
            .six: 6,
            .seven: 7,
            .eight: 8,
        ]
        for (digits, value) in samples {
            let sut = makeSUT()
            let code = makeCode(digits: digits)

            let encoded = sut.encode(code: code)
            XCTAssertEqual(encoded.digits, value)
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> ManagedOTPCodeEncoder {
        let anyContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        return ManagedOTPCodeEncoder(context: anyContext)
    }

    private func makeCode(
        type: OTPAuthType = .totp(),
        secret: OTPAuthSecret = .empty(),
        algorithm: OTPAuthAlgorithm = .sha1,
        digits: OTPAuthDigits = .six,
        accountName: String = "any",
        issuer: String? = nil
    ) -> OTPAuthCode {
        OTPAuthCode(
            type: type,
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            accountName: accountName,
            issuer: issuer
        )
    }
}
