import Foundation
import SwiftData
import TestHelpers
import VaultCore
import XCTest
@testable import VaultFeed

final class PersistedVaultItemEncoderTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var context: ModelContext!

    override func setUp() async throws {
        try await super.setUp()

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistedVaultItem.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDown() async throws {
        try await super.tearDown()

        context = nil
    }
}

// MARK: - Metadata

extension PersistedVaultItemEncoderTests {
    func test_encodeMetadata_usesSameDateForCreatedAndUpdated() {
        var currentEpochSeconds = 100.0
        let sut = makeSUT(currentDate: {
            // Ensures the time increments every time the date is fetched
            currentEpochSeconds += 1
            return Date(timeIntervalSince1970: currentEpochSeconds)
        })

        let newItem = sut.encode(item: uniqueWritableVaultItem())
        XCTAssertEqual(newItem.createdDate, newItem.updatedDate)
    }

    func test_encodeMetadata_existingItemRetainsUUID() {
        let sut = makeSUT()

        let existing = sut.encode(item: uniqueWritableVaultItem())
        let existingID = existing.id

        let newCode = sut.encode(item: uniqueWritableVaultItem(), existing: existing)
        XCTAssertEqual(newCode.id, existingID, "ID should not change for update")
    }

    func test_encodeMetadata_existingItemRetainsCreatedDate() {
        let sut1 = makeSUT(currentDate: { Date(timeIntervalSince1970: 100) })

        let existing = sut1.encode(item: uniqueWritableVaultItem())
        let existingCreatedDate = existing.createdDate

        let sut2 = makeSUT(currentDate: { Date(timeIntervalSince1970: 200) })
        let newCode = sut2.encode(item: uniqueWritableVaultItem(), existing: existing)
        XCTAssertEqual(newCode.createdDate, existingCreatedDate, "Date should not change for update")
    }

    func test_encodeMetadata_existingItemUpdatesUpdatedDate() {
        let sut1 = makeSUT(currentDate: { Date(timeIntervalSince1970: 100) })

        let existing = sut1.encode(item: uniqueWritableVaultItem())

        let sut2 = makeSUT(currentDate: { Date(timeIntervalSince1970: 200) })
        let newCode = sut2.encode(item: uniqueWritableVaultItem(), existing: existing)
        XCTAssertEqual(newCode.updatedDate, Date(timeIntervalSince1970: 200), "Date should not change for update")
    }

    func test_encodeMetadata_newItemGeneratesRandomUUID() {
        var seen = Set<UUID>()
        for _ in 0 ..< 100 {
            let sut = makeSUT()
            let code = makeWritable(code: makeCodeValue())

            let encoded = sut.encode(item: code)
            XCTAssertFalse(seen.contains(encoded.id))
            seen.insert(encoded.id)
        }
    }

    func test_encodeMetadata_newItemUserDescriptionEncodesString() {
        let sut = makeSUT()
        let desc = UUID().uuidString
        let code = makeWritable(userDescription: desc, code: uniqueCode())

        let encoded = sut.encode(item: code)
        XCTAssertEqual(encoded.userDescription, desc)
    }

    func test_encodeMetadata_newItemIgnoresForNoColor() {
        let sut = makeSUT()
        let code = makeWritable(code: uniqueCode(), color: nil)

        let encoded = sut.encode(item: code)
        XCTAssertNil(encoded.color)
    }

    func test_encodeMetadata_newItemWritesColorValues() {
        let sut = makeSUT()
        let color = VaultItemColor(red: 0.5, green: 0.6, blue: 0.7)
        let code = makeWritable(code: uniqueCode(), color: color)

        let encoded = sut.encode(item: code)
        XCTAssertEqual(encoded.color?.red, 0.5)
        XCTAssertEqual(encoded.color?.green, 0.6)
        XCTAssertEqual(encoded.color?.blue, 0.7)
    }

    func test_encodeMetadata_existingItemOverridesColorValues() {
        let sut1 = makeSUT()

        var existingItem = uniqueWritableVaultItem()
        existingItem.color = VaultItemColor(red: 0.1, green: 0.2, blue: 0.3)
        let existing = sut1.encode(item: existingItem)

        let color = VaultItemColor(red: 0.5, green: 0.6, blue: 0.7)
        let sut2 = makeSUT()
        let code = makeWritable(code: uniqueCode(), color: color)

        let newCode = sut2.encode(item: code, existing: existing)
        XCTAssertEqual(newCode.color?.red, 0.5)
        XCTAssertEqual(newCode.color?.green, 0.6)
        XCTAssertEqual(newCode.color?.blue, 0.7)
    }
}

// MARK: - OTP

extension PersistedVaultItemEncoderTests {
    func test_encodeOTP_digitsEncodesToInt32() {
        let samples: [OTPAuthDigits: Int32] = [
            OTPAuthDigits(value: 6): 6,
            OTPAuthDigits(value: 7): 7,
            OTPAuthDigits(value: 8): 8,
            OTPAuthDigits(value: 12): 12,
            OTPAuthDigits(value: 100): 100,
        ]
        for (digits, value) in samples {
            let sut = makeSUT()
            let code = makeWritable(code: makeCodeValue(digits: digits))

            let encoded = sut.encode(item: code)
            XCTAssertEqual(encoded.otpDetails?.digits, value)
        }
    }

    func test_encodeOTP_authTypeEncodesKindTOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .totp()))

        let encoded = sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.authType, "totp")
    }

    func test_encodeOTP_authTypeEncodesKindHOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .hotp()))

        let encoded = sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.authType, "hotp")
    }

    func test_encodeOTP_periodForTOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .totp(period: 69)))

        let encoded = sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.period, 69)
    }

    func test_encodeOTP_noPeriodForHOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .hotp()))

        let encoded = sut.encode(item: code)
        XCTAssertNil(encoded.otpDetails?.period)
    }

    func test_encodeOTP_counterForHOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .hotp(counter: 69)))

        let encoded = sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.counter, 69)
    }

    func test_encodeOTP_noCounterForTOTP() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .totp()))

        let encoded = sut.encode(item: code)
        XCTAssertNil(encoded.otpDetails?.counter)
    }

    func test_encodeOTP_accountName() {
        let sut = makeSUT()
        let accountName = UUID().uuidString
        let code = makeWritable(code: makeCodeValue(accountName: accountName))

        let encoded = sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.accountName, accountName)
    }

    func test_encodeOTP_isser() {
        let sut = makeSUT()
        let issuer = UUID().uuidString
        let code = makeWritable(code: makeCodeValue(issuer: issuer))

        let encoded = sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.issuer, issuer)
    }

    func test_encodeOTP_isserNil() {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(issuer: nil))

        let encoded = sut.encode(item: code)
        XCTAssertNil(encoded.otpDetails?.issuer)
    }

    func test_encodeOTP_algorithm() {
        let expected: [OTPAuthAlgorithm: String] = [
            .sha1: "SHA1",
            .sha256: "SHA256",
            .sha512: "SHA512",
        ]
        for (algo, expected) in expected {
            let sut = makeSUT()
            let code = makeWritable(code: makeCodeValue(algorithm: algo))

            let encoded = sut.encode(item: code)
            XCTAssertEqual(encoded.otpDetails?.algorithm, expected)
        }
    }

    func test_encodeOTP_secretFormat() {
        let expected: [OTPAuthSecret.Format: String] = [
            .base32: "BASE_32",
        ]
        for (format, expected) in expected {
            let sut = makeSUT()
            let secret = OTPAuthSecret(data: Data(), format: format)
            let code = makeWritable(code: makeCodeValue(secret: secret))

            let encoded = sut.encode(item: code)
            XCTAssertEqual(encoded.otpDetails?.secretFormat, expected)
        }
    }

    func test_encodeOTP_secretToBinary() {
        let sut = makeSUT()
        let secretData = Data([0xFF, 0xEE, 0x66, 0x77, 0x22])
        let secret = OTPAuthSecret(data: secretData, format: .base32)
        let code = makeWritable(code: makeCodeValue(secret: secret))

        let encoded = sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.secretData, secretData)
    }
}

// MARK: - Secure Note

extension PersistedVaultItemEncoderTests {
    func test_encodeNote_title() {
        let sut = makeSUT()
        let item = makeWritable(note: makeSecretNoteValue(title: "this is my title"))

        let encoded = sut.encode(item: item)
        XCTAssertEqual(encoded.noteDetails?.title, "this is my title")
    }

    func test_encodeNote_contents() {
        let sut = makeSUT()
        let item = makeWritable(note: makeSecretNoteValue(contents: "this is the note contents"))

        let encoded = sut.encode(item: item)
        XCTAssertEqual(encoded.noteDetails?.rawContents, "this is the note contents")
    }
}

// MARK: - Helpers

extension PersistedVaultItemEncoderTests {
    private func makeSUT(currentDate: @escaping () -> Date = { Date() }) -> PersistedVaultItemEncoder {
        PersistedVaultItemEncoder(context: context, currentDate: currentDate)
    }

    private func makeWritable(
        userDescription: String = "",
        code: OTPAuthCode,
        color: VaultItemColor? = nil
    ) -> StoredVaultItem.Write {
        StoredVaultItem.Write(userDescription: userDescription, color: color, item: .otpCode(code))
    }

    private func makeCodeValue(
        type: OTPAuthType = .totp(),
        secret: OTPAuthSecret = .empty(),
        algorithm: OTPAuthAlgorithm = .default,
        digits: OTPAuthDigits = .default,
        accountName: String = "any",
        issuer: String? = nil
    ) -> OTPAuthCode {
        OTPAuthCode(
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

    private func makeWritable(
        userDescription: String = "",
        note: SecureNote,
        color: VaultItemColor? = nil
    ) -> StoredVaultItem.Write {
        StoredVaultItem.Write(userDescription: userDescription, color: color, item: .secureNote(note))
    }

    private func makeSecretNoteValue(
        title: String = "note title",
        contents: String = "note contents"
    ) -> SecureNote {
        SecureNote(title: title, contents: contents)
    }
}
