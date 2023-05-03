import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

final class ManagedOTPCodeEncoderTests: XCTestCase {
    func test_generateUUID_generatesRandomUUID() {
        var seen = Set<UUID>()
        for _ in 0 ..< 100 {
            let sut = makeSUT()
            let code = makeCode()

            let encoded = sut.encode(code: code)
            XCTAssertFalse(seen.contains(encoded.id))
            seen.insert(encoded.id)
        }
    }

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

    func test_encodeType_encodesKindTOTP() {
        let sut = makeSUT()
        let code = makeCode(type: .totp())

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.authType, "totp")
    }

    func test_encodeType_encodesKindHOTP() {
        let sut = makeSUT()
        let code = makeCode(type: .hotp())

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.authType, "hotp")
    }

    func test_encodePeriod_encodesPeriodForTOTP() {
        let sut = makeSUT()
        let code = makeCode(type: .totp(period: 69))

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.period, 69)
    }

    func test_encodePeriod_doesNotEncodePeriodForHOTP() {
        let sut = makeSUT()
        let code = makeCode(type: .hotp())

        let encoded = sut.encode(code: code)
        XCTAssertNil(encoded.period)
    }

    func test_encodeCounter_encodesCounterForHOTP() {
        let sut = makeSUT()
        let code = makeCode(type: .hotp(counter: 69))

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.counter, 69)
    }

    func test_encodePeriod_doesNotEncodePeriodForTOTP() {
        let sut = makeSUT()
        let code = makeCode(type: .totp())

        let encoded = sut.encode(code: code)
        XCTAssertNil(encoded.counter)
    }

    func test_encodeAccountName_encodesCorrectAccountName() {
        let sut = makeSUT()
        let accountName = UUID().uuidString
        let code = makeCode(accountName: accountName)

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.accountName, accountName)
    }

    func test_encodeIssuer_encodesCorrectIssuerIfPresent() {
        let sut = makeSUT()
        let issuer = UUID().uuidString
        let code = makeCode(issuer: issuer)

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.issuer, issuer)
    }

    func test_encodeIssuer_encodesNilIfNotPresent() {
        let sut = makeSUT()
        let code = makeCode(issuer: nil)

        let encoded = sut.encode(code: code)
        XCTAssertNil(encoded.issuer)
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
