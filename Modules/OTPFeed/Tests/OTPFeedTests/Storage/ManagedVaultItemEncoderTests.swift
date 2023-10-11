import CoreData
import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

final class ManagedVaultItemEncoderTests: XCTestCase {
    private var persistentContainer: NSPersistentContainer!

    override func setUpWithError() throws {
        super.setUp()

        persistentContainer = try NSPersistentContainer.testContainer(storeName: String(describing: self))
    }

    override func tearDown() {
        persistentContainer = nil

        super.tearDown()
    }

    func test_encodeExisting_retainsExistingUUID() {
        let sut = makeSUT()

        let existing = sut.encode(code: uniqueWritableCode())
        let existingID = existing.id

        let newCode = sut.encode(code: uniqueWritableCode(), into: existing)
        XCTAssertEqual(newCode.id, existingID, "ID should not change for update")
    }

    func test_encodeExisting_retainsCreatedDate() {
        let sut1 = makeSUT(currentDate: { Date(timeIntervalSince1970: 100) })

        let existing = sut1.encode(code: uniqueWritableCode())
        let existingCreatedDate = existing.createdDate

        let sut2 = makeSUT(currentDate: { Date(timeIntervalSince1970: 200) })
        let newCode = sut2.encode(code: uniqueWritableCode(), into: existing)
        XCTAssertEqual(newCode.createdDate, existingCreatedDate, "Date should not change for update")
    }

    func test_encodeExisting_updatesUpdatedDate() {
        let sut1 = makeSUT(currentDate: { Date(timeIntervalSince1970: 100) })

        let existing = sut1.encode(code: uniqueWritableCode())

        let sut2 = makeSUT(currentDate: { Date(timeIntervalSince1970: 200) })
        let newCode = sut2.encode(code: uniqueWritableCode(), into: existing)
        XCTAssertEqual(newCode.updatedDate, Date(timeIntervalSince1970: 200), "Date should not change for update")
    }

    func test_generateUUID_generatesRandomUUID() {
        var seen = Set<UUID>()
        for _ in 0 ..< 100 {
            let sut = makeSUT()
            let code = makeWritable(code: makeCodeValue())

            let encoded = sut.encode(code: code)
            XCTAssertFalse(seen.contains(encoded.id))
            seen.insert(encoded.id)
        }
    }

    func test_encodeDigits_encodesToNSNumber() {
        let samples: [OTPAuthDigits: NSNumber] = [
            OTPAuthDigits(value: 6): 6,
            OTPAuthDigits(value: 7): 7,
            OTPAuthDigits(value: 8): 8,
            OTPAuthDigits(value: 12): 12,
            OTPAuthDigits(value: 100): 100,
        ]
        for (digits, value) in samples {
            let sut = makeSUT()
            let code = makeWritable(code: makeCodeValue(digits: digits))

            let encoded = sut.encode(code: code)
            XCTAssertEqual(encoded.digits, value)
        }
    }

    func test_encodeType_encodesKindTOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .totp()))

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.authType, "totp")
    }

    func test_encodeType_encodesKindHOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .hotp()))

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.authType, "hotp")
    }

    func test_encodePeriod_encodesPeriodForTOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .totp(period: 69)))

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.period, 69)
    }

    func test_encodePeriod_doesNotEncodePeriodForHOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .hotp()))

        let encoded = sut.encode(code: code)
        XCTAssertNil(encoded.period)
    }

    func test_encodeCounter_encodesCounterForHOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .hotp(counter: 69)))

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.counter, 69)
    }

    func test_encodePeriod_doesNotEncodePeriodForTOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .totp()))

        let encoded = sut.encode(code: code)
        XCTAssertNil(encoded.counter)
    }

    func test_encodeAccountName_encodesCorrectAccountName() {
        let sut = makeSUT()
        let accountName = UUID().uuidString
        let code = makeWritable(code: makeCodeValue(accountName: accountName))

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.accountName, accountName)
    }

    func test_encodeIssuer_encodesCorrectIssuerIfPresent() {
        let sut = makeSUT()
        let issuer = UUID().uuidString
        let code = makeWritable(code: makeCodeValue(issuer: issuer))

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.issuer, issuer)
    }

    func test_encodeIssuer_encodesNilIfNotPresent() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(issuer: nil))

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
            let code = makeWritable(code: makeCodeValue(algorithm: algo))

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
            let code = makeWritable(code: makeCodeValue(secret: secret))

            let encoded = sut.encode(code: code)
            XCTAssertEqual(encoded.secretFormat, expected)
        }
    }

    func test_encodeSecret_encodesSecretBinaryData() {
        let sut = makeSUT()
        let secretData = Data([0xFF, 0xEE, 0x66, 0x77, 0x22])
        let secret = OTPAuthSecret(data: secretData, format: .base32)
        let code = makeWritable(code: makeCodeValue(secret: secret))

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.secretData, secretData)
    }

    func test_encodeUserDescription_encodesNil() {
        let sut = makeSUT()
        let code = makeWritable(userDescription: nil, code: uniqueCode())

        let encoded = sut.encode(code: code)
        XCTAssertNil(encoded.userDescription)
    }

    func test_encodeUserDescription_encodesString() {
        let sut = makeSUT()
        let desc = UUID().uuidString
        let code = makeWritable(userDescription: desc, code: uniqueCode())

        let encoded = sut.encode(code: code)
        XCTAssertEqual(encoded.userDescription, desc)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = { Date() }) -> ManagedVaultItemEncoder {
        ManagedVaultItemEncoder(context: anyContext(), currentDate: currentDate)
    }

    private func makeWritable(
        userDescription: String? = nil,
        code: GenericOTPAuthCode
    ) -> StoredVaultItem.Write {
        StoredVaultItem.Write(userDescription: userDescription, code: code)
    }

    private func makeCodeValue(
        type: OTPAuthType = .totp(),
        secret: OTPAuthSecret = .empty(),
        algorithm: OTPAuthAlgorithm = .default,
        digits: OTPAuthDigits = .default,
        accountName: String = "any",
        issuer: String? = nil
    ) -> GenericOTPAuthCode {
        GenericOTPAuthCode(
            type: type,
            data: .init(
                secret: secret,
                algorithm: algorithm,
                digits: digits,
                accountName: accountName,
                issuer: issuer
            )
        )
    }

    private func anyContext() -> NSManagedObjectContext {
        persistentContainer.viewContext
    }
}
