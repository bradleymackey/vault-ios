import CoreData
import Foundation
import VaultCore
import XCTest
@testable import VaultFeed

final class ManagedVaultItemDecoderTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var persistentContainer: NSPersistentContainer!

    override func setUpWithError() throws {
        super.setUp()

        persistentContainer = try NSPersistentContainer.testContainer(storeName: String(describing: self))
    }

    override func tearDown() {
        persistentContainer = nil

        super.tearDown()
    }
}

// MARK: - Metadata

extension ManagedVaultItemDecoderTests {
    func test_decodeMetadataID_decodesToCorrectInput() throws {
        let sut = makeSUT()

        let id = UUID()
        let code = makeManagedCode(id: id)

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.id, id)
    }

    func test_decodeMetadataCreatedDate_decodesToCorrectInput() throws {
        let sut = makeSUT()

        let date = Date(timeIntervalSince1970: 123_456)
        let code = makeManagedCode(createdDate: date)

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.metadata.created, date)
    }

    func test_decodeMetadataUpdatedDate_decodesToCorrectInput() throws {
        let sut = makeSUT()

        let date = Date(timeIntervalSince1970: 123_456)
        let code = makeManagedCode(updatedDate: date)

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.metadata.updated, date)
    }

    func test_decodeMetadataUserDescription_decodesToCorrectInput() throws {
        let sut = makeSUT()

        let description = "this is my description \(UUID().uuidString)"
        let code = makeManagedCode(userDescription: description)

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.metadata.userDescription, description)
    }

    func test_decodeMetadataColor_decodesNilIfAllMissing() throws {
        let sut = makeSUT()

        let code = makeManagedCode(
            colorRed: nil,
            colorBlue: nil,
            colorGreen: nil
        )

        let decoded = try sut.decode(item: code)
        XCTAssertNil(decoded.metadata.color)
    }

    func test_decodeMetadataColor_decodesNilIfAnyMissing() throws {
        let sut = makeSUT()

        let code = makeManagedCode(
            colorRed: 0.5 as NSNumber,
            colorBlue: nil,
            colorGreen: nil
        )

        let decoded = try sut.decode(item: code)
        XCTAssertNil(decoded.metadata.color)
    }

    func test_decodeMetadataColor_decodesColorValues() throws {
        let sut = makeSUT()

        let code = makeManagedCode(
            colorRed: 0.5 as NSNumber,
            colorBlue: 0.6 as NSNumber,
            colorGreen: 0.7 as NSNumber
        )

        let decoded = try sut.decode(item: code)
        let expectedColor = VaultItemColor(red: 0.5, green: 0.7, blue: 0.6)
        XCTAssertEqual(decoded.metadata.color, expectedColor)
    }
}

// MARK: - OTP Code

extension ManagedVaultItemDecoderTests {
    func test_decodeDigits_decodesToCorrectValue() throws {
        let samples: [OTPAuthDigits: NSNumber] = [
            OTPAuthDigits(value: 0): 0,
            OTPAuthDigits(value: 6): 6,
            OTPAuthDigits(value: 7): 7,
            OTPAuthDigits(value: 8): 8,
            OTPAuthDigits(value: 100): 100,
            OTPAuthDigits(value: 1024): 1024,
        ]
        for (digits, value) in samples {
            let sut = makeSUT()
            let code = makeManagedCode(digits: value)

            let decoded = try sut.decode(item: code)
            XCTAssertEqual(decoded.item.otpCode?.data.digits, digits)
        }
    }

    func test_decodeDigits_throwsForInvalidDigits() throws {
        let unsupported: [NSNumber] = [-33, 333_333]
        for value in unsupported {
            let sut = makeSUT()
            let code = makeManagedCode(digits: value)

            XCTAssertThrowsError(try sut.decode(item: code))
        }
    }

    func test_decodeAccountName_decodesExpected() throws {
        let accountName = UUID().uuidString
        let code = makeManagedCode(accountName: accountName)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.item.otpCode?.data.accountName, accountName)
    }

    func test_decodeIssuer_decodesValueIfExists() throws {
        let issuerName = UUID().uuidString
        let code = makeManagedCode(issuer: issuerName)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.item.otpCode?.data.issuer, issuerName)
    }

    func test_decodeIssuer_decodesNilIfDoesNotExist() throws {
        let code = makeManagedCode(issuer: nil)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertNil(decoded.item.otpCode?.data.issuer)
    }

    func test_decodeType_decodesTOTPWithPeriod() throws {
        let code = makeManagedCode(authType: "totp", period: 69)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.item.otpCode?.type, .totp(period: 69))
    }

    func test_decodeType_totpWithoutPeriodThrows() throws {
        let code = makeManagedCode(authType: "totp", period: nil)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: code))
    }

    func test_decodeType_decodesHOTPWithCounter() throws {
        let code = makeManagedCode(authType: "hotp", counter: 69)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.item.otpCode?.type, .hotp(counter: 69))
    }

    func test_decodeType_hotpWithoutCounterThrows() throws {
        let code = makeManagedCode(authType: "hotp", counter: nil)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: code))
    }

    func test_decodeAlgorithm_decodesValidAlgorithm() throws {
        let expected: [OTPAuthAlgorithm: String] = [
            .sha1: "SHA1",
            .sha256: "SHA256",
            .sha512: "SHA512",
        ]
        for (algo, string) in expected {
            let code = makeManagedCode(algorithm: string)
            let sut = makeSUT()

            let decoded = try sut.decode(item: code)
            XCTAssertEqual(decoded.item.otpCode?.data.algorithm, algo)
        }
    }

    func test_decodeAlgorithm_throwsIfAlgorithmUnknown() throws {
        let code = makeManagedCode(algorithm: "OTHER")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: code))
    }

    func test_decodeSecret_decodesFormat() throws {
        let expected: [OTPAuthSecret.Format: String] = [
            .base32: "BASE_32",
        ]
        for (format, string) in expected {
            let code = makeManagedCode(secretFormat: string)
            let sut = makeSUT()

            let decoded = try sut.decode(item: code)
            XCTAssertEqual(decoded.item.otpCode?.data.secret.format, format)
        }
    }

    func test_decodeSecret_throwsIfFormatIsInvalid() throws {
        let code = makeManagedCode(secretFormat: "INVALID")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: code))
    }

    func test_decodeSecret_decodesEmptyData() throws {
        let code = makeManagedCode(secretData: Data())
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.item.otpCode?.data.secret.data, Data())
    }

    func test_decodeSecret_decodesExistingData() throws {
        let data = Data([0xFF, 0xEE, 0x11, 0x12, 0x13, 0x56])
        let code = makeManagedCode(secretData: data)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.item.otpCode?.data.secret.data, data)
    }
}

// MARK: - Secure Note

extension ManagedVaultItemDecoderTests {
    func test_decodeNoteTitle_decodesToCorrectInput() throws {
        let sut = makeSUT()

        let title = "this is my note title"
        let note = makeManagedSecureNote(title: title)

        let decoded = try sut.decode(item: note)
        XCTAssertEqual(decoded.item.secureNote?.title, title)
    }

    func test_decodeNoteUserContents_decodesToCorrectInput() throws {
        let sut = makeSUT()

        let contents = "this is my note contents"
        let note = makeManagedSecureNote(contents: contents)

        let decoded = try sut.decode(item: note)
        XCTAssertEqual(decoded.item.secureNote?.contents, contents)
    }
}

// MARK: - Helpers

extension ManagedVaultItemDecoderTests {
    private func makeSUT() -> ManagedVaultItemDecoder {
        ManagedVaultItemDecoder()
    }

    private func makeManagedCode(
        id: UUID = UUID(),
        createdDate: Date = Date(),
        updatedDate: Date = Date(),
        userDescription: String? = "user description",
        accountName: String = "any",
        algorithm: String = "SHA1",
        authType: String = "totp",
        counter: NSNumber? = UInt32(30) as NSNumber,
        digits: NSNumber = UInt32(6) as NSNumber,
        issuer: String? = "issuer",
        period: NSNumber? = UInt32(30) as NSNumber,
        secretData: Data = Data(),
        secretFormat: String = "BASE_32",
        colorRed: NSNumber? = nil,
        colorBlue: NSNumber? = nil,
        colorGreen: NSNumber? = nil
    ) -> ManagedVaultItem {
        let context = anyContext()
        let item = ManagedVaultItem(context: context)
        item.id = id
        item.createdDate = createdDate
        item.updatedDate = updatedDate
        item.userDescription = userDescription
        item.colorRed = colorRed
        item.colorBlue = colorBlue
        item.colorGreen = colorGreen

        let otp = ManagedOTPDetails(context: context)
        otp.accountName = accountName
        otp.algorithm = algorithm
        otp.authType = authType
        otp.counter = counter
        otp.digits = digits
        otp.issuer = issuer
        otp.period = period
        otp.secretData = secretData
        otp.secretFormat = secretFormat

        item.otpDetails = otp
        return item
    }

    private func makeManagedSecureNote(
        id: UUID = UUID(),
        createdDate: Date = Date(),
        updatedDate: Date = Date(),
        userDescription: String? = "user description",
        title: String = "my note title",
        contents: String = "my note contents"
    ) -> ManagedVaultItem {
        let context = anyContext()
        let item = ManagedVaultItem(context: context)
        item.id = id
        item.createdDate = createdDate
        item.updatedDate = updatedDate
        item.userDescription = userDescription

        let note = ManagedNoteDetails(context: context)
        note.title = title
        note.rawContents = contents

        item.noteDetails = note
        return item
    }

    private func anyContext() -> NSManagedObjectContext {
        persistentContainer.viewContext
    }
}
