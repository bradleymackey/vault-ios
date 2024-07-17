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
    func test_encodeMetadata_usesSameDateForCreatedAndUpdated() throws {
        var currentEpochSeconds = 100.0
        let sut = makeSUT(currentDate: {
            // Ensures the time increments every time the date is fetched
            currentEpochSeconds += 1
            return Date(timeIntervalSince1970: currentEpochSeconds)
        })

        let newItem = try sut.encode(item: uniqueVaultItem().makeWritable())
        XCTAssertEqual(newItem.createdDate, newItem.updatedDate)
    }

    func test_encodeMetadata_existingItemRetainsUUID() throws {
        let sut = makeSUT()

        let existing = try sut.encode(item: uniqueVaultItem().makeWritable())
        let existingID = existing.id

        let newCode = try sut.encode(item: uniqueVaultItem().makeWritable(), existing: existing)
        XCTAssertEqual(newCode.id, existingID, "ID should not change for update")
    }

    func test_encodeMetadata_existingItemRetainsCreatedDate() throws {
        let sut1 = makeSUT(currentDate: { Date(timeIntervalSince1970: 100) })

        let existing = try sut1.encode(item: uniqueVaultItem().makeWritable())
        let existingCreatedDate = existing.createdDate

        let sut2 = makeSUT(currentDate: { Date(timeIntervalSince1970: 200) })
        let newCode = try sut2.encode(item: uniqueVaultItem().makeWritable(), existing: existing)
        XCTAssertEqual(newCode.createdDate, existingCreatedDate, "Date should not change for update")
    }

    func test_encodeMetadata_existingItemUpdatesUpdatedDate() throws {
        let sut1 = makeSUT(currentDate: { Date(timeIntervalSince1970: 100) })

        let existing = try sut1.encode(item: uniqueVaultItem().makeWritable())

        let sut2 = makeSUT(currentDate: { Date(timeIntervalSince1970: 200) })
        let newCode = try sut2.encode(item: uniqueVaultItem().makeWritable(), existing: existing)
        XCTAssertEqual(newCode.updatedDate, Date(timeIntervalSince1970: 200), "Date should not change for update")
    }

    func test_encodeMetadata_newItemGeneratesRandomUUID() throws {
        var seen = Set<UUID>()
        for _ in 0 ..< 100 {
            let sut = makeSUT()
            let code = makeWritable(code: makeCodeValue())

            let encoded = try sut.encode(item: code)
            XCTAssertFalse(seen.contains(encoded.id))
            seen.insert(encoded.id)
        }
    }

    func test_encodeMetadata_newItemUserDescriptionEncodesString() throws {
        let sut = makeSUT()
        let desc = UUID().uuidString
        let code = makeWritable(userDescription: desc, code: uniqueCode())

        let encoded = try sut.encode(item: code)
        XCTAssertEqual(encoded.userDescription, desc)
    }

    func test_encodeMetadata_newItemIgnoresForNoColor() throws {
        let sut = makeSUT()
        let code = makeWritable(code: uniqueCode(), color: nil)

        let encoded = try sut.encode(item: code)
        XCTAssertNil(encoded.color)
    }

    func test_encodeMetadata_newItemWritesColorValues() throws {
        let sut = makeSUT()
        let color = VaultItemColor(red: 0.5, green: 0.6, blue: 0.7)
        let code = makeWritable(code: uniqueCode(), color: color)

        let encoded = try sut.encode(item: code)
        XCTAssertEqual(encoded.color?.red, 0.5)
        XCTAssertEqual(encoded.color?.green, 0.6)
        XCTAssertEqual(encoded.color?.blue, 0.7)
    }

    func test_encodeMetadata_existingItemOverridesColorValues() throws {
        let sut1 = makeSUT()

        var existingItem = uniqueVaultItem().makeWritable()
        existingItem.color = VaultItemColor(red: 0.1, green: 0.2, blue: 0.3)
        let existing = try sut1.encode(item: existingItem)

        let color = VaultItemColor(red: 0.5, green: 0.6, blue: 0.7)
        let sut2 = makeSUT()
        let code = makeWritable(code: uniqueCode(), color: color)

        let newCode = try sut2.encode(item: code, existing: existing)
        XCTAssertEqual(newCode.color?.red, 0.5)
        XCTAssertEqual(newCode.color?.green, 0.6)
        XCTAssertEqual(newCode.color?.blue, 0.7)
    }

    func test_encodeMetadata_newItemEncodesVisibilityLevels() throws {
        let mapping: [VaultItemVisibility: String] = [
            .always: "ALWAYS",
            .onlySearch: "ONLY_SEARCH",
        ]

        for (value, key) in mapping {
            let sut1 = makeSUT()
            var existingItem = uniqueVaultItem().makeWritable()
            existingItem.visibility = value
            let existing = try sut1.encode(item: existingItem)

            XCTAssertEqual(existing.visibility, key)
        }
    }

    func test_encodeMetadata_existingItemEncodesVisibilityLevels() throws {
        let mapping: [VaultItemVisibility: String] = [
            .always: "ALWAYS",
            .onlySearch: "ONLY_SEARCH",
        ]

        for (value, key) in mapping {
            let sut1 = makeSUT()
            var item1 = uniqueVaultItem().makeWritable()
            item1.visibility = .onlySearch
            let existing = try sut1.encode(item: item1)

            var item2 = uniqueVaultItem().makeWritable()
            item2.visibility = value
            let existing2 = try sut1.encode(item: item2, existing: existing)

            XCTAssertEqual(existing2.visibility, key)
        }
    }

    func test_encodeMetadata_newItemEncodesSearchableLevels() throws {
        let mapping: [VaultItemSearchableLevel: String] = [
            .full: "FULL",
            .none: "NONE",
            .onlyTitle: "ONLY_TITLE",
            .onlyPassphrase: "ONLY_PASSPHRASE",
        ]

        for (value, key) in mapping {
            let sut1 = makeSUT()
            var existingItem = uniqueVaultItem().makeWritable()
            existingItem.searchableLevel = value
            let existing = try sut1.encode(item: existingItem)

            XCTAssertEqual(existing.searchableLevel, key)
        }
    }

    func test_encodeMetadata_existingItemEncodesSearchableLevels() throws {
        let mapping: [VaultItemSearchableLevel: String] = [
            .full: "FULL",
            .none: "NONE",
            .onlyTitle: "ONLY_TITLE",
            .onlyPassphrase: "ONLY_PASSPHRASE",
        ]

        for (value, key) in mapping {
            let sut1 = makeSUT()
            var item1 = uniqueVaultItem().makeWritable()
            item1.searchableLevel = .none
            let existing = try sut1.encode(item: item1)

            var item2 = uniqueVaultItem().makeWritable()
            item2.searchableLevel = value
            let existing2 = try sut1.encode(item: item2, existing: existing)

            XCTAssertEqual(existing2.searchableLevel, key)
        }
    }

    func test_encodeMetadata_newItemEncodesEmptyTags() throws {
        let sut = makeSUT()
        let item = uniqueVaultItem(tags: []).makeWritable()

        let encoded = try sut.encode(item: item)
        XCTAssertEqual(encoded.tags, [])
    }

    func test_encodeMetadata_newItemEncodesSomeTags() throws {
        let id1 = UUID()
        let id2 = UUID()
        let sut = makeSUT()
        let item = uniqueVaultItem(tags: [.init(id: id1), .init(id: id2)]).makeWritable()

        let persisted1 = makePersistedTag(id: id1)
        let persisted2 = makePersistedTag(id: id2)
        let encoded = try sut.encode(item: item)
        XCTAssertEqual(encoded.tags.map(\.id).reducedToSet(), [persisted1.id, persisted2.id])
    }

    func test_encodeMetadata_existingItemEncodesEmptyTags() throws {
        let id1 = UUID()
        _ = makePersistedTag(id: id1)
        let sut = makeSUT()
        let item = uniqueVaultItem(tags: [.init(id: id1)]).makeWritable()
        let existing = try sut.encode(item: item)

        let itemNew = uniqueVaultItem(tags: []).makeWritable()
        let encoded = try sut.encode(item: itemNew, existing: existing)
        XCTAssertEqual(encoded.tags, [])
    }

    func test_encodeMetadata_existingItemEncodesSomeTags() throws {
        let id1 = UUID()
        _ = makePersistedTag(id: id1)
        let sut = makeSUT()
        let item = uniqueVaultItem(tags: [.init(id: id1)]).makeWritable()
        let existing = try sut.encode(item: item)

        let id2 = UUID()
        let persisted2 = makePersistedTag(id: id2)
        let itemNew = uniqueVaultItem(tags: [.init(id: id2)]).makeWritable()
        let encoded = try sut.encode(item: itemNew, existing: existing)
        XCTAssertEqual(encoded.tags.map(\.id).reducedToSet(), [persisted2.id])
    }
}

// MARK: - OTP

extension PersistedVaultItemEncoderTests {
    func test_encodeOTP_digitsEncodesToInt32() throws {
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

            let encoded = try sut.encode(item: code)
            XCTAssertEqual(encoded.otpDetails?.digits, value)
        }
    }

    func test_encodeOTP_authTypeEncodesKindTOTP() throws {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .totp()))

        let encoded = try sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.authType, "totp")
    }

    func test_encodeOTP_authTypeEncodesKindHOTP() throws {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .hotp()))

        let encoded = try sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.authType, "hotp")
    }

    func test_encodeOTP_periodForTOTP() throws {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .totp(period: 69)))

        let encoded = try sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.period, 69)
    }

    func test_encodeOTP_noPeriodForHOTP() throws {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .hotp()))

        let encoded = try sut.encode(item: code)
        XCTAssertNil(encoded.otpDetails?.period)
    }

    func test_encodeOTP_counterForHOTP() throws {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .hotp(counter: 69)))

        let encoded = try sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.counter, 69)
    }

    func test_encodeOTP_noCounterForTOTP() throws {
        let sut = makeSUT()
        let code = makeWritable(code: makeCodeValue(type: .totp()))

        let encoded = try sut.encode(item: code)
        XCTAssertNil(encoded.otpDetails?.counter)
    }

    func test_encodeOTP_accountName() throws {
        let sut = makeSUT()
        let accountName = UUID().uuidString
        let code = makeWritable(code: makeCodeValue(accountName: accountName))

        let encoded = try sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.accountName, accountName)
    }

    func test_encodeOTP_isser() throws {
        let sut = makeSUT()
        let issuer = UUID().uuidString
        let code = makeWritable(code: makeCodeValue(issuer: issuer))

        let encoded = try sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.issuer, issuer)
    }

    func test_encodeOTP_algorithm() throws {
        let expected: [OTPAuthAlgorithm: String] = [
            .sha1: "SHA1",
            .sha256: "SHA256",
            .sha512: "SHA512",
        ]
        for (algo, expected) in expected {
            let sut = makeSUT()
            let code = makeWritable(code: makeCodeValue(algorithm: algo))

            let encoded = try sut.encode(item: code)
            XCTAssertEqual(encoded.otpDetails?.algorithm, expected)
        }
    }

    func test_encodeOTP_secretFormat() throws {
        let expected: [OTPAuthSecret.Format: String] = [
            .base32: "BASE_32",
        ]
        for (format, expected) in expected {
            let sut = makeSUT()
            let secret = OTPAuthSecret(data: Data(), format: format)
            let code = makeWritable(code: makeCodeValue(secret: secret))

            let encoded = try sut.encode(item: code)
            XCTAssertEqual(encoded.otpDetails?.secretFormat, expected)
        }
    }

    func test_encodeOTP_secretToBinary() throws {
        let sut = makeSUT()
        let secretData = Data([0xFF, 0xEE, 0x66, 0x77, 0x22])
        let secret = OTPAuthSecret(data: secretData, format: .base32)
        let code = makeWritable(code: makeCodeValue(secret: secret))

        let encoded = try sut.encode(item: code)
        XCTAssertEqual(encoded.otpDetails?.secretData, secretData)
    }
}

// MARK: - Secure Note

extension PersistedVaultItemEncoderTests {
    func test_encodeNote_title() throws {
        let sut = makeSUT()
        let item = makeWritable(note: makeSecretNoteValue(title: "this is my title"))

        let encoded = try sut.encode(item: item)
        XCTAssertEqual(encoded.noteDetails?.title, "this is my title")
    }

    func test_encodeNote_contents() throws {
        let sut = makeSUT()
        let item = makeWritable(note: makeSecretNoteValue(contents: "this is the note contents"))

        let encoded = try sut.encode(item: item)
        XCTAssertEqual(encoded.noteDetails?.contents, "this is the note contents")
    }
}

// MARK: - Helpers

extension PersistedVaultItemEncoderTests {
    private func makeSUT(currentDate: @escaping () -> Date = { Date() }) -> PersistedVaultItemEncoder {
        PersistedVaultItemEncoder(context: context, currentDate: currentDate)
    }

    private func makePersistedTag(id: UUID = UUID(), title: String = "Any") -> PersistedVaultTag {
        let tag = PersistedVaultTag(id: id, title: title, color: nil, iconName: nil, items: [])
        context.insert(tag)
        return tag
    }

    private func makeWritable(
        userDescription: String = "",
        code: OTPAuthCode,
        color: VaultItemColor? = nil,
        visibility: VaultItemVisibility = .always,
        searchableLevel: VaultItemSearchableLevel = .full,
        tags: Set<VaultItemTag.Identifier> = [],
        searchPassphrase: String = ""
    ) -> VaultItem.Write {
        VaultItem.Write(
            userDescription: userDescription,
            color: color,
            item: .otpCode(code),
            tags: tags,
            visibility: visibility,
            searchableLevel: searchableLevel,
            searchPassphase: searchPassphrase
        )
    }

    private func makeCodeValue(
        type: OTPAuthType = .totp(),
        secret: OTPAuthSecret = .empty(),
        algorithm: OTPAuthAlgorithm = .default,
        digits: OTPAuthDigits = .default,
        accountName: String = "any",
        issuer: String = ""
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
        color: VaultItemColor? = nil,
        tags: Set<VaultItemTag.Identifier> = []
    ) -> VaultItem.Write {
        VaultItem.Write(
            userDescription: userDescription,
            color: color,
            item: .secureNote(note),
            tags: tags,
            visibility: .always,
            searchableLevel: .full,
            searchPassphase: ""
        )
    }

    private func makeSecretNoteValue(
        title: String = "note title",
        contents: String = "note contents"
    ) -> SecureNote {
        SecureNote(title: title, contents: contents)
    }
}
