import Foundation
import TestHelpers
import VaultBackup
import VaultCore
import XCTest
@testable import VaultFeed

final class VaultBackupItemDecoderTests: XCTestCase {
    // MARK: - Note

    func test_decodeNote_decodesNote() throws {
        let id = UUID()
        let createdDate = Date()
        let updateDate = Date()
        let description = "my user description"
        let tag = UUID()
        let item = VaultBackupItem(
            id: id,
            createdDate: createdDate,
            updatedDate: updateDate,
            relativeOrder: 77777,
            userDescription: description,
            tags: [tag],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: "hello",
            lockState: .notLocked,
            tintColor: .init(red: 0.1, green: 0.2, blue: 0.3),
            item: .note(data: .init(title: "title", rawContents: "contents"))
        )
        let sut = makeSUT()

        let decodedItem = try sut.decode(backupItem: item)

        XCTAssertEqual(decodedItem.id, id)
        XCTAssertEqual(decodedItem.metadata.created, createdDate)
        XCTAssertEqual(decodedItem.metadata.updated, updateDate)
        XCTAssertEqual(decodedItem.metadata.userDescription, description)
        XCTAssertEqual(decodedItem.metadata.visibility, .always)
        XCTAssertEqual(decodedItem.metadata.searchableLevel, .full)
        XCTAssertEqual(decodedItem.metadata.searchPassphrase, "hello")
        XCTAssertEqual(decodedItem.metadata.color, .init(red: 0.1, green: 0.2, blue: 0.3))
        XCTAssertEqual(decodedItem.metadata.tags, [.init(id: tag)])
        XCTAssertEqual(decodedItem.metadata.lockState, .notLocked)
        XCTAssertEqual(decodedItem.metadata.relativeOrder, 77777)
        XCTAssertEqual(decodedItem.item.secureNote?.title, "title")
        XCTAssertEqual(decodedItem.item.secureNote?.contents, "contents")
    }

    func test_decodeNote_decodeswithNilContentsIntoEmptyString() throws {
        let item = anyNoteItem(contents: nil)
        let sut = makeSUT()

        let decodedItem = try sut.decode(backupItem: item)

        XCTAssertEqual(decodedItem.item.secureNote?.contents, "")
    }

    // MARK: - OTP Code

    func test_decodeOTP_decodesTOTPCode() throws {
        let id = UUID()
        let createdDate = Date()
        let updateDate = Date()
        let description = "my user description"
        let item = VaultBackupItem(
            id: id,
            createdDate: createdDate,
            updatedDate: updateDate,
            relativeOrder: 1234,
            userDescription: description,
            tags: [],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: "pass",
            lockState: .lockedWithNativeSecurity,
            tintColor: .init(red: 0.1, green: 0.2, blue: 0.3),
            item: .otp(data: .init(
                secretFormat: "BASE_32",
                secretData: Data(hex: "ababababa"),
                authType: "totp",
                period: 30,
                counter: nil,
                algorithm: "SHA1",
                digits: 5,
                accountName: "my acc",
                issuer: "my iss"
            ))
        )
        let sut = makeSUT()

        let decodedItem = try sut.decode(backupItem: item)

        let expectedSecret = OTPAuthSecret(data: Data(hex: "ababababa"), format: .base32)
        XCTAssertEqual(decodedItem.id, id)
        XCTAssertEqual(decodedItem.metadata.created, createdDate)
        XCTAssertEqual(decodedItem.metadata.updated, updateDate)
        XCTAssertEqual(decodedItem.metadata.userDescription, description)
        XCTAssertEqual(decodedItem.metadata.searchableLevel, .full)
        XCTAssertEqual(decodedItem.metadata.searchPassphrase, "pass")
        XCTAssertEqual(decodedItem.metadata.visibility, .always)
        XCTAssertEqual(decodedItem.metadata.color, .init(red: 0.1, green: 0.2, blue: 0.3))
        XCTAssertEqual(decodedItem.metadata.lockState, .lockedWithNativeSecurity)
        XCTAssertEqual(decodedItem.metadata.relativeOrder, 1234)
        XCTAssertEqual(decodedItem.item.otpCode?.type, .totp(period: 30))
        XCTAssertEqual(decodedItem.item.otpCode?.data.secret, expectedSecret)
        XCTAssertEqual(decodedItem.item.otpCode?.data.accountName, "my acc")
        XCTAssertEqual(decodedItem.item.otpCode?.data.issuer, "my iss")
        XCTAssertEqual(decodedItem.item.otpCode?.data.digits, OTPAuthDigits(value: 5))
        XCTAssertEqual(decodedItem.item.otpCode?.data.algorithm, .sha1)
    }

    func test_decodeOTP_decodesHOTPCode() throws {
        let id = UUID()
        let createdDate = Date()
        let updateDate = Date()
        let description = "my user description"
        let item = VaultBackupItem(
            id: id,
            createdDate: createdDate,
            updatedDate: updateDate,
            relativeOrder: 4321,
            userDescription: description,
            tags: [],
            visibility: .onlySearch,
            searchableLevel: .full,
            searchPassphrase: "nice",
            lockState: .notLocked,
            tintColor: .init(red: 0.2, green: 0.2, blue: 0.3),
            item: .otp(data: .init(
                secretFormat: "BASE_32",
                secretData: Data(hex: "ababababaff"),
                authType: "hotp",
                period: nil,
                counter: 10,
                algorithm: "SHA1",
                digits: 7,
                accountName: "my acc a",
                issuer: "my iss a"
            ))
        )
        let sut = makeSUT()

        let decodedItem = try sut.decode(backupItem: item)

        let expectedSecret = OTPAuthSecret(data: Data(hex: "ababababaff"), format: .base32)
        XCTAssertEqual(decodedItem.id, id)
        XCTAssertEqual(decodedItem.metadata.created, createdDate)
        XCTAssertEqual(decodedItem.metadata.updated, updateDate)
        XCTAssertEqual(decodedItem.metadata.relativeOrder, 4321)
        XCTAssertEqual(decodedItem.metadata.userDescription, description)
        XCTAssertEqual(decodedItem.metadata.searchableLevel, .full)
        XCTAssertEqual(decodedItem.metadata.visibility, .onlySearch)
        XCTAssertEqual(decodedItem.metadata.searchPassphrase, "nice")
        XCTAssertEqual(decodedItem.metadata.color, .init(red: 0.2, green: 0.2, blue: 0.3))
        XCTAssertEqual(decodedItem.metadata.lockState, .notLocked)
        XCTAssertEqual(decodedItem.item.otpCode?.type, .hotp(counter: 10))
        XCTAssertEqual(decodedItem.item.otpCode?.data.secret, expectedSecret)
        XCTAssertEqual(decodedItem.item.otpCode?.data.accountName, "my acc a")
        XCTAssertEqual(decodedItem.item.otpCode?.data.issuer, "my iss a")
        XCTAssertEqual(decodedItem.item.otpCode?.data.digits, OTPAuthDigits(value: 7))
        XCTAssertEqual(decodedItem.item.otpCode?.data.algorithm, .sha1)
    }

    func test_decodeOTP_succeedsForAnyOTPItem() throws {
        // Checks that 'anyOTPItem' has a valid item, to ensure the throwing tests are correct.
        let otp = anyOTPItem()
        let sut = makeSUT()

        XCTAssertNoThrow(try sut.decode(backupItem: otp))
    }

    func test_decodeOTP_failsToDecodesAlgorithms() throws {
        let otp_sha1 = anyOTPItem(algorithm: "SHA1")
        let item_sha1 = try makeSUT().decode(backupItem: otp_sha1)
        XCTAssertEqual(item_sha1.item.otpCode?.data.algorithm, .sha1)

        let otp_sha256 = anyOTPItem(algorithm: "SHA256")
        let item_sha256 = try makeSUT().decode(backupItem: otp_sha256)
        XCTAssertEqual(item_sha256.item.otpCode?.data.algorithm, .sha256)

        let otp_sha512 = anyOTPItem(algorithm: "SHA512")
        let item_sha512 = try makeSUT().decode(backupItem: otp_sha512)
        XCTAssertEqual(item_sha512.item.otpCode?.data.algorithm, .sha512)
    }

    func test_decodeOTP_failsForInvalidType() throws {
        let otp = anyOTPItem(type: "inv")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(backupItem: otp))
    }

    func test_decodeOTP_failsToDecodeTOTPIfNoPeriod() throws {
        let otp = anyOTPItem(type: "totp", period: nil)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(backupItem: otp))
    }

    func test_decodeOTP_failsToDecodeHOTPIfNoCounter() throws {
        let otp = anyOTPItem(type: "hotp", counter: nil)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(backupItem: otp))
    }

    func test_decodeOTP_failsToDecodeInvalidSecretFormat() throws {
        let otp = anyOTPItem(secretFormat: "inv")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(backupItem: otp))
    }

    func test_decodeOTP_failsToDecodeInvalidAlgorithm() throws {
        let otp = anyOTPItem(algorithm: "inv")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(backupItem: otp))
    }
}

// MARK: - Helpers

extension VaultBackupItemDecoderTests {
    private func makeSUT() -> VaultBackupItemDecoder {
        VaultBackupItemDecoder()
    }

    private func anyNoteItem(contents: String? = nil) -> VaultBackupItem {
        let id = UUID()
        let createdDate = Date()
        let updateDate = Date()
        let description = "my user description"
        return VaultBackupItem(
            id: id,
            createdDate: createdDate,
            updatedDate: updateDate,
            relativeOrder: nil,
            userDescription: description,
            tags: [],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: "",
            lockState: .notLocked,
            tintColor: .init(red: 0.1, green: 0.2, blue: 0.3),
            item: .note(data: .init(title: "title", rawContents: contents))
        )
    }

    private func anyOTPItem(
        type: String = "totp",
        period: UInt64? = 30,
        counter: UInt64? = 0,
        secretFormat: String = "BASE_32",
        algorithm: String = "SHA1"
    ) -> VaultBackupItem {
        let createdDate = Date()
        let updateDate = Date()
        let description = "my user description"
        return VaultBackupItem(
            id: UUID(),
            createdDate: createdDate,
            updatedDate: updateDate,
            relativeOrder: nil,
            userDescription: description,
            tags: [],
            visibility: .onlySearch,
            searchableLevel: .full,
            searchPassphrase: "",
            lockState: .notLocked,
            tintColor: .init(red: 0.2, green: 0.2, blue: 0.3),
            item: .otp(data: .init(
                secretFormat: secretFormat,
                secretData: Data(hex: "ababababaff"),
                authType: type,
                period: period,
                counter: counter,
                algorithm: algorithm,
                digits: 7,
                accountName: "my acc a",
                issuer: "my iss a"
            ))
        )
    }
}
