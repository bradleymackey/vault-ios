import Foundation
import TestHelpers
import VaultBackup
import VaultCore
import XCTest
@testable import VaultFeed

final class VaultBackupItemEncoderTests: XCTestCase {
    // MARK: Full items

    func test_encode_encodesNote() {
        let id = UUID()
        let createdDate = Date(timeIntervalSince1970: 123_456)
        let updateDate = Date(timeIntervalSince1970: 456_789)
        let description = "my user description"
        let note = SecureNote(title: "title", contents: "contents")
        let item = StoredVaultItem(
            metadata: .init(
                id: id,
                created: createdDate,
                updated: updateDate,
                userDescription: description,
                color: nil
            ),
            item: .secureNote(note)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        XCTAssertEqual(encodedItem.id, id)
        XCTAssertEqual(encodedItem.createdDate, createdDate)
        XCTAssertEqual(encodedItem.updatedDate, updateDate)
        XCTAssertEqual(encodedItem.userDescription, description)
        XCTAssertEqual(encodedItem.item.noteData?.title, "title")
        XCTAssertEqual(encodedItem.item.noteData?.rawContents, "contents")
    }

    func test_encode_encodesTOTPCode() {
        let id = UUID()
        let createdDate = Date(timeIntervalSince1970: 123_456)
        let updateDate = Date(timeIntervalSince1970: 456_789)
        let description = "my user description"
        let secret = OTPAuthSecret(data: .init(hex: "ababa"), format: .base32)
        let code = OTPAuthCode(
            type: .totp(period: 36),
            data: .init(
                secret: secret,
                algorithm: .sha256,
                digits: .init(value: 8),
                accountName: "my account name",
                issuer: "my issuer"
            )
        )
        let item = StoredVaultItem(
            metadata: .init(
                id: id,
                created: createdDate,
                updated: updateDate,
                userDescription: description,
                color: nil
            ),
            item: .otpCode(code)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        XCTAssertEqual(encodedItem.id, id)
        XCTAssertEqual(encodedItem.createdDate, createdDate)
        XCTAssertEqual(encodedItem.updatedDate, updateDate)
        XCTAssertEqual(encodedItem.userDescription, description)
        XCTAssertEqual(encodedItem.item.codeData?.accountName, "my account name")
        XCTAssertEqual(encodedItem.item.codeData?.issuer, "my issuer")
        XCTAssertEqual(encodedItem.item.codeData?.algorithm, "SHA256")
        XCTAssertEqual(encodedItem.item.codeData?.authType, "TOTP")
        XCTAssertEqual(encodedItem.item.codeData?.period, 36)
        XCTAssertNil(encodedItem.item.codeData?.counter, "No counter for TOTP")
        XCTAssertEqual(encodedItem.item.codeData?.digits, 8)
        XCTAssertEqual(encodedItem.item.codeData?.secretData, Data(hex: "ababa"))
        XCTAssertEqual(encodedItem.item.codeData?.secretFormat, "BASE_32")
    }

    func test_encode_encodesHOTPCode() {
        let id = UUID()
        let createdDate = Date(timeIntervalSince1970: 123_456)
        let updateDate = Date(timeIntervalSince1970: 456_789)
        let description = "my user description"
        let secret = OTPAuthSecret(data: .init(hex: "ababa"), format: .base32)
        let code = OTPAuthCode(
            type: .hotp(counter: 69),
            data: .init(
                secret: secret,
                algorithm: .sha256,
                digits: .init(value: 8),
                accountName: "my account name",
                issuer: "my issuer"
            )
        )
        let item = StoredVaultItem(
            metadata: .init(
                id: id,
                created: createdDate,
                updated: updateDate,
                userDescription: description,
                color: nil
            ),
            item: .otpCode(code)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        XCTAssertEqual(encodedItem.id, id)
        XCTAssertEqual(encodedItem.createdDate, createdDate)
        XCTAssertEqual(encodedItem.updatedDate, updateDate)
        XCTAssertEqual(encodedItem.userDescription, description)
        XCTAssertEqual(encodedItem.item.codeData?.accountName, "my account name")
        XCTAssertEqual(encodedItem.item.codeData?.issuer, "my issuer")
        XCTAssertEqual(encodedItem.item.codeData?.algorithm, "SHA256")
        XCTAssertEqual(encodedItem.item.codeData?.authType, "HOTP")
        XCTAssertEqual(encodedItem.item.codeData?.counter, 69)
        XCTAssertNil(encodedItem.item.codeData?.period, "No period for HOTP")
        XCTAssertEqual(encodedItem.item.codeData?.digits, 8)
        XCTAssertEqual(encodedItem.item.codeData?.secretData, Data(hex: "ababa"))
        XCTAssertEqual(encodedItem.item.codeData?.secretFormat, "BASE_32")
    }

    // MARK: Cases

    func test_encode_otpAlgorithmTypes() {
        let sut = makeSUT()

        let code1 = anyOTPVaultItem(algorithm: .sha1)
        let encoded1 = sut.encode(storedItem: code1)
        XCTAssertEqual(encoded1.item.codeData?.algorithm, "SHA1")

        let code2 = anyOTPVaultItem(algorithm: .sha256)
        let encoded2 = sut.encode(storedItem: code2)
        XCTAssertEqual(encoded2.item.codeData?.algorithm, "SHA256")

        let code3 = anyOTPVaultItem(algorithm: .sha512)
        let encoded3 = sut.encode(storedItem: code3)
        XCTAssertEqual(encoded3.item.codeData?.algorithm, "SHA512")
    }
}

// MARK: - Helpers

extension VaultBackupItemEncoderTests {
    private func makeSUT() -> VaultBackupItemEncoder {
        VaultBackupItemEncoder()
    }

    private func anyOTPVaultItem(algorithm: OTPAuthAlgorithm) -> StoredVaultItem {
        let code = OTPAuthCode(
            type: .hotp(counter: 69),
            data: .init(
                secret: .empty(),
                algorithm: algorithm,
                digits: .init(value: 8),
                accountName: "my account name",
                issuer: "my issuer"
            )
        )
        return StoredVaultItem(
            metadata: .init(id: UUID(), created: Date(), updated: Date(), userDescription: "any", color: nil),
            item: .otpCode(code)
        )
    }
}

extension VaultBackupItem.Item {
    fileprivate var noteData: VaultBackupItem.Note? {
        switch self {
        case let .note(note): note
        default: nil
        }
    }

    fileprivate var codeData: VaultBackupItem.OTP? {
        switch self {
        case let .otp(code): code
        default: nil
        }
    }
}
