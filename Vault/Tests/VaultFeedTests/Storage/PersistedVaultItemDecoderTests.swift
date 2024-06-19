import Foundation
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

        XCTAssertEqual(decoded.id, id)
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
        let noteDetails = makePersistedNoteDetails(rawContents: contents)
        let item = makePersistedItem(noteDetails: noteDetails, otpDetails: nil)

        let decoded = try sut.decode(item: item)
        XCTAssertEqual(decoded.item.secureNote?.contents, contents)
    }
}

// MARK: - Helpers

extension PersistedVaultItemDecoderTests {
    private func makeSUT() -> PersistedVaultItemDecoder {
        PersistedVaultItemDecoder()
    }

    private func makePersistedItem(
        id: UUID = UUID(),
        createdDate: Date = Date(),
        updatedDate: Date = Date(),
        userDescription: String = "",
        color: PersistedVaultItem.Color? = nil,
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
        )
    ) -> PersistedVaultItem {
        let item = PersistedVaultItem(
            id: id,
            createdDate: createdDate,
            updatedDate: updatedDate,
            userDescription: userDescription,
            color: color,
            noteDetails: noteDetails,
            otpDetails: otpDetails
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
        rawContents: String? = nil
    ) -> PersistedNoteDetails {
        PersistedNoteDetails(title: title, rawContents: rawContents)
    }
}
