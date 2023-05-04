import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

final class ManagedOTPCodeEncoderTests: XCTestCase {
    func test_encodeExisting_retainsExistingUUID() {
        let sut = makeSUT()

        let existing = sut.encode(code: makeCode())
        let existingID = existing.id

        let newCode = sut.encode(code: makeCode(), into: existing)
        XCTAssertEqual(newCode.id, existingID, "ID should not change for update")
    }

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

    func test_encodeAlgorithm_encodesToString() {
        let expected: [OTPAuthAlgorithm: String] = [
            .sha1: "SHA1",
            .sha256: "SHA256",
            .sha512: "SHA512",
        ]
        for (algo, expected) in expected {
            let sut = makeSUT()
            let code = makeCode(algorithm: algo)

            let encoded = sut.encode(code: code)
            XCTAssertEqual(encoded.algorithm, expected)
        }
    }

    func test_encodeSecret_formatEncodesToString() {
        let expected: [OTPAuthSecret.Format: String] = [
            .base32: "BASE_32",
        ]
        for (format, expected) in expected {
            let sut = makeSUT()
            let secret = OTPAuthSecret(data: Data(), format: format)
            let code = makeCode(secret: secret)

            let encoded = sut.encode(code: code)
            XCTAssertEqual(encoded.secretFormat, expected)
        }
    }

    func test_encodeSecret_encodesSecretBinaryData() {
        let sut = makeSUT()
        let secretData = Data([0xFF, 0xEE, 0x66, 0x77, 0x22])
        let secret = OTPAuthSecret(data: secretData, format: .base32)
        let code = makeCode(secret: secret)

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.secretData, secretData)
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
