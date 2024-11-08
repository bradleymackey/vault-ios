import Foundation
import FoundationExtensions
import SwiftData
import TestHelpers
import VaultCore
import XCTest
@testable import VaultFeed

final class PersistedVaultItemDecoderTests: XCTestCase {
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

// MARK: - Generic

extension PersistedVaultItemDecoderTests {
    func test_decodeItem_missingItemDetail() throws {
        let sut = makeSUT()

        let persistedItem = makePersistedItem(
            noteDetails: nil,
            otpDetails: nil
        )

        XCTAssertThrowsError(try sut.decode(item: persistedItem))
    }
}

// MARK: - Metadata

extension PersistedVaultItemDecoderTests {
    func test_decodeMetadata_id() throws {
        let id = UUID()
        let item = makePersistedItem(id: id)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.id.rawValue, id)
    }

    func test_decodeMetadata_createdDate() throws {
        let date = Date()
        let item = makePersistedItem(createdDate: date)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.metadata.created, date)
    }

    func test_decodeMetadata_updatedDate() throws {
        let date = Date()
        let item = makePersistedItem(updatedDate: date)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.metadata.updated, date)
    }

    func test_decodeMetadata_userDescription() throws {
        let description = "my description \(UUID().uuidString)"
        let item = makePersistedItem(userDescription: description)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.metadata.userDescription, description)
    }

    func test_decodeMetadata_colorIsNil() throws {
        let item = makePersistedItem(
            color: nil
        )
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertNil(decoded.metadata.color)
    }

    func test_decodeMetadata_decodesColorValues() throws {
        let item = makePersistedItem(
            color: .init(red: 0.7, green: 0.6, blue: 0.5)
        )
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        let expectedColor = VaultItemColor(red: 0.7, green: 0.6, blue: 0.5)
        XCTAssertEqual(decoded.metadata.color, expectedColor)
    }

    func test_decodeMetadata_decodesVisibilityLevels() throws {
        let mapping: [VaultItemVisibility: String] = [
            .always: "ALWAYS",
            .onlySearch: "ONLY_SEARCH",
        ]
        for (value, key) in mapping {
            let item = makePersistedItem(visibility: key)
            let sut = makeSUT()

            let decoded = try sut.decode(item: item)

            XCTAssertEqual(decoded.metadata.visibility, value)
        }
    }

    func test_decodeMetadata_throwsForInvalidVisibilityLevel() throws {
        let item = makePersistedItem(visibility: "INVALID")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: item))
    }

    func test_decodeMetadata_decodesSearchableLevels() throws {
        let mapping: [VaultItemSearchableLevel: String] = [
            .full: "FULL",
            .none: "NONE",
            .onlyTitle: "ONLY_TITLE",
            .onlyPassphrase: "ONLY_PASSPHRASE",
        ]
        for (value, key) in mapping {
            let item = makePersistedItem(searchableLevel: key)
            let sut = makeSUT()

            let decoded = try sut.decode(item: item)

            XCTAssertEqual(decoded.metadata.searchableLevel, value)
        }
    }

    func test_decodeMetadata_throwsForInvalidSearchableLevel() throws {
        let item = makePersistedItem(searchableLevel: "INVALID")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: item))
    }

    func test_decodeMetadata_decodesSearchPassphrase() throws {
        let item = makePersistedItem(searchPassphrase: "my secret - super secret")
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.metadata.searchPassphrase, "my secret - super secret")
    }

    func test_decodeMetadata_decodesKillphrase() throws {
        let item = makePersistedItem(killphrase: "kill me now")
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.metadata.killphrase, "kill me now")
    }

    func test_decodeMetadata_decodesEmptyItemTags() throws {
        let item = makePersistedItem(tags: [])
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.metadata.tags, [])
    }

    func test_decodeMetadata_decodesItemTags() throws {
        let id1 = UUID()
        let id2 = UUID()
        let item = makePersistedItem(tags: [makePersistedTag(id: id1), makePersistedTag(id: id2)])
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.metadata.tags, [.init(id: id1), .init(id: id2)])
    }

    func test_decodeLockState_nilIsNotLocked() throws {
        let item = makePersistedItem(lockState: nil)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.metadata.lockState, .notLocked)
    }

    func test_decodeLockState_notLocked() throws {
        let item = makePersistedItem(lockState: "NOT_LOCKED")
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.metadata.lockState, .notLocked)
    }

    func test_decodeLockState_lockedNative() throws {
        let item = makePersistedItem(lockState: "LOCKED_NATIVE")
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.metadata.lockState, .lockedWithNativeSecurity)
    }

    func test_decodeLockState_invalidValueThrows() throws {
        let item = makePersistedItem(lockState: "INVALID")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: item))
    }
}

// MARK: - OTP Code

extension PersistedVaultItemDecoderTests {
    func test_decodeOTP_digits() throws {
        let samples: [OTPAuthDigits: Int32] = [
            OTPAuthDigits(value: 0): 0,
            OTPAuthDigits(value: 6): 6,
            OTPAuthDigits(value: 7): 7,
            OTPAuthDigits(value: 8): 8,
            OTPAuthDigits(value: 100): 100,
            OTPAuthDigits(value: 1024): 1024,
        ]
        for (digits, value) in samples {
            let sut = makeSUT()
            let otpDetails = makePersistedOTPDetails(digits: value)
            let item = makePersistedItem(otpDetails: otpDetails)

            let decoded = try sut.decode(item: item)
            XCTAssertEqual(decoded.item.otpCode?.data.digits, digits)
        }
    }

    func test_decodeOTP_invalidDigits() throws {
        let unsupported: [Int32] = [-33, 333_333]
        for value in unsupported {
            let sut = makeSUT()
            let otpDetails = makePersistedOTPDetails(digits: value)
            let item = makePersistedItem(otpDetails: otpDetails)

            XCTAssertThrowsError(try sut.decode(item: item))
        }
    }

    func test_decodeOTP_accountName() throws {
        let accountName = UUID().uuidString
        let otpDetails = makePersistedOTPDetails(accountName: accountName)
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.item.otpCode?.data.accountName, accountName)
    }

    func test_decodeOTP_issuer() throws {
        let issuerName = UUID().uuidString
        let otpDetails = makePersistedOTPDetails(issuer: issuerName)
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.item.otpCode?.data.issuer, issuerName)
    }

    func test_decodeOTP_authTypeTOTPWithPeriod() throws {
        let otpDetails = makePersistedOTPDetails(authType: "totp", period: 69)
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.item.otpCode?.type, .totp(period: 69))
    }

    func test_decodeOTP_authTypeTOTPWithoutPeriodThrows() throws {
        let otpDetails = makePersistedOTPDetails(authType: "totp", period: nil)
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: item))
    }

    func test_decodeOTP_authTypeHOTPWithCounter() throws {
        let otpDetails = makePersistedOTPDetails(authType: "hotp", counter: 69)
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.item.otpCode?.type, .hotp(counter: 69))
    }

    func test_decodeOTP_authTypeHOTPWithoutCounterThrows() throws {
        let otpDetails = makePersistedOTPDetails(authType: "hotp", counter: nil)
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: item))
    }

    func test_decodeOTP_algorithm() throws {
        let expected: [OTPAuthAlgorithm: String] = [
            .sha1: "SHA1",
            .sha256: "SHA256",
            .sha512: "SHA512",
        ]
        for (algo, string) in expected {
            let otpDetails = makePersistedOTPDetails(algorithm: string)
            let item = makePersistedItem(otpDetails: otpDetails)
            let sut = makeSUT()

            let decoded = try sut.decode(item: item)
            XCTAssertEqual(decoded.item.otpCode?.data.algorithm, algo)
        }
    }

    func test_decodeOTP_invalidAlgorithmThrows() throws {
        let otpDetails = makePersistedOTPDetails(algorithm: "OTHER")
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: item))
    }

    func test_decodeOTP_secretFormat() throws {
        let expected: [OTPAuthSecret.Format: String] = [
            .base32: "BASE_32",
        ]
        for (format, string) in expected {
            let otpDetails = makePersistedOTPDetails(secretFormat: string)
            let item = makePersistedItem(otpDetails: otpDetails)
            let sut = makeSUT()

            let decoded = try sut.decode(item: item)
            XCTAssertEqual(decoded.item.otpCode?.data.secret.format, format)
        }
    }

    func test_decodeOTP_secretFormatInvalidThrows() throws {
        let otpDetails = makePersistedOTPDetails(secretFormat: "INVALID")
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: item))
    }

    func test_decodeOTP_emptySecret() throws {
        let otpDetails = makePersistedOTPDetails(secretData: Data())
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.item.otpCode?.data.secret.data, Data())
    }

    func test_decodeOTP_nonEmptySecret() throws {
        let data = Data([0xFF, 0xEE, 0x11, 0x12, 0x13, 0x56])
        let otpDetails = makePersistedOTPDetails(secretData: data)
        let item = makePersistedItem(otpDetails: otpDetails)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.item.otpCode?.data.secret.data, data)
    }
}

// MARK: - Secure Note

extension PersistedVaultItemDecoderTests {
    func test_decodeNote_title() throws {
        let sut = makeSUT()

        let title = "this is my note title"
        let noteDetails = makePersistedNoteDetails(title: title)
        let item = makePersistedItem(noteDetails: noteDetails, otpDetails: nil)

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.item.secureNote?.title, title)
    }

    func test_decodeNote_contents() throws {
        let sut = makeSUT()

        let contents = "this is my note contents"
        let noteDetails = makePersistedNoteDetails(contents: contents)
        let item = makePersistedItem(noteDetails: noteDetails, otpDetails: nil)

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.item.secureNote?.contents, contents)
    }
}

// MARK: - EncryptedItem

extension PersistedVaultItemDecoderTests {
    func test_decodeEncryptedItem_correctly() throws {
        let sut = makeSUT()

        let itemData = Data.random(count: 16)
        let itemAuth = Data.random(count: 16)
        let itemEncryptionIV = Data.random(count: 16)
        let itemKeygenSalt = Data.random(count: 16)
        let itemKeygenSignature = "my sig"
        let encryptedItem = PersistedEncryptedItemDetails(
            version: "1.0.3",
            title: "cool title",
            data: itemData,
            authentication: itemAuth,
            encryptionIV: itemEncryptionIV,
            keygenSalt: itemKeygenSalt,
            keygenSignature: itemKeygenSignature
        )
        let item = makePersistedItem(otpDetails: nil, encryptedItemDetails: encryptedItem)

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.item.encryptedItem?.version, "1.0.3")
        XCTAssertEqual(decoded.item.encryptedItem?.title, "cool title")
        XCTAssertEqual(decoded.item.encryptedItem?.data, itemData)
        XCTAssertEqual(decoded.item.encryptedItem?.authentication, itemAuth)
        XCTAssertEqual(decoded.item.encryptedItem?.encryptionIV, itemEncryptionIV)
        XCTAssertEqual(decoded.item.encryptedItem?.keygenSalt, itemKeygenSalt)
        XCTAssertEqual(decoded.item.encryptedItem?.keygenSignature, itemKeygenSignature)
    }
}

// MARK: - Helpers

extension PersistedVaultItemDecoderTests {
    private func makeSUT() -> PersistedVaultItemDecoder {
        PersistedVaultItemDecoder()
    }

    private func makePersistedTag(
        id: UUID = UUID(),
        title: String = "Any"
    ) -> PersistedVaultTag {
        let tag = PersistedVaultTag(id: id, title: title, color: nil, iconName: nil, items: [])
        context.insert(tag)
        return tag
    }

    private func makePersistedItem(
        id: UUID = UUID(),
        relativeOrder: UInt64 = .min,
        createdDate: Date = Date(),
        updatedDate: Date = Date(),
        userDescription: String = "",
        visibility: String = "ALWAYS",
        searchableLevel: String = "FULL",
        searchPassphrase: String? = nil,
        killphrase: String? = nil,
        lockState: String? = nil,
        color: PersistedColor? = nil,
        tags: [PersistedVaultTag] = [],
        noteDetails: PersistedNoteDetails? = nil,
        otpDetails: PersistedOTPDetails? = .init(
            accountName: "",
            issuer: "",
            algorithm: VaultEncodingConstants.OTPAuthAlgorithm.sha1,
            authType: VaultEncodingConstants.OTPAuthType.totp,
            counter: 0,
            digits: 1,
            period: 0,
            secretData: Data(),
            secretFormat: VaultEncodingConstants.OTPAuthSecret.Format.base32
        ),
        encryptedItemDetails: PersistedEncryptedItemDetails? = nil
    ) -> PersistedVaultItem {
        let item = PersistedVaultItem(
            id: id,
            relativeOrder: relativeOrder,
            createdDate: createdDate,
            updatedDate: updatedDate,
            userDescription: userDescription,
            visibility: visibility,
            searchableLevel: searchableLevel,
            searchPassphrase: searchPassphrase,
            killphrase: killphrase,
            lockState: lockState,
            color: color,
            tags: tags,
            noteDetails: noteDetails,
            otpDetails: otpDetails,
            encryptedItemDetails: encryptedItemDetails
        )
        context.insert(item)
        return item
    }

    private func makePersistedOTPDetails(
        accountName: String = "",
        algorithm: String = VaultEncodingConstants.OTPAuthAlgorithm.sha1,
        authType: String = VaultEncodingConstants.OTPAuthType.totp,
        counter: Int64? = 0,
        digits: Int32 = 1,
        issuer: String = "",
        period: Int64? = 0,
        secretData: Data = Data(),
        secretFormat: String = VaultEncodingConstants.OTPAuthSecret.Format.base32
    ) -> PersistedOTPDetails {
        PersistedOTPDetails(
            accountName: accountName,
            issuer: issuer,
            algorithm: algorithm,
            authType: authType,
            counter: counter,
            digits: digits,
            period: period,
            secretData: secretData,
            secretFormat: secretFormat
        )
    }

    private func makePersistedNoteDetails(
        title: String = "my title",
        contents: String = "",
        format: String = VaultEncodingConstants.TextFormat.plain
    ) -> PersistedNoteDetails {
        PersistedNoteDetails(title: title, contents: contents, format: format)
    }
}
