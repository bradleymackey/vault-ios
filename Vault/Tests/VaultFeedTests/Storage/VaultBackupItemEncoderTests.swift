import Foundation
import FoundationExtensions
import TestHelpers
import VaultBackup
import VaultCore
import XCTest
@testable import VaultFeed

final class VaultBackupItemEncoderTests: XCTestCase {
    // MARK: Full items

    func test_encode_encodesNote() {
        let id = Identifier<VaultItem>()
        let createdDate = Date(timeIntervalSince1970: 123_456)
        let updateDate = Date(timeIntervalSince1970: 456_789)
        let description = "my user description"
        let note = SecureNote(title: "title", contents: "contents")
        let tags: Set<Identifier<VaultItemTag>> = [.init(id: UUID())]
        let item = VaultItem(
            metadata: .init(
                id: id,
                created: createdDate,
                updated: updateDate,
                relativeOrder: 999_995,
                userDescription: description,
                tags: tags,
                visibility: .always,
                searchableLevel: .onlyTitle,
                searchPassphrase: "",
                lockState: .notLocked,
                color: .init(red: 0.1, green: 0.2, blue: 0.3)
            ),
            item: .secureNote(note)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        XCTAssertEqual(encodedItem.id, id.rawValue)
        XCTAssertEqual(encodedItem.createdDate, createdDate)
        XCTAssertEqual(encodedItem.updatedDate, updateDate)
        XCTAssertEqual(encodedItem.userDescription, description)
        XCTAssertEqual(encodedItem.tags, tags.reducedToSet(\.id))
        XCTAssertEqual(encodedItem.relativeOrder, 999_995)
        XCTAssertEqual(encodedItem.item.noteData?.title, "title")
        XCTAssertEqual(encodedItem.item.noteData?.rawContents, "contents")
        XCTAssertEqual(encodedItem.visibility, .always)
        XCTAssertEqual(encodedItem.searchableLevel, .onlyTitle)
        XCTAssertEqual(encodedItem.lockState, .notLocked)
        XCTAssertEqual(encodedItem.tintColor, .init(red: 0.1, green: 0.2, blue: 0.3))
    }

    func test_encode_encodesTOTPCode() {
        let id = Identifier<VaultItem>()
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
        let item = VaultItem(
            metadata: .init(
                id: id,
                created: createdDate,
                updated: updateDate,
                relativeOrder: 1234,
                userDescription: description,
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "hello",
                lockState: .lockedWithNativeSecurity,
                color: .init(red: 0.1, green: 0.2, blue: 0.3)
            ),
            item: .otpCode(code)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        XCTAssertEqual(encodedItem.id, id.rawValue)
        XCTAssertEqual(encodedItem.createdDate, createdDate)
        XCTAssertEqual(encodedItem.updatedDate, updateDate)
        XCTAssertEqual(encodedItem.relativeOrder, 1234)
        XCTAssertEqual(encodedItem.visibility, .always)
        XCTAssertEqual(encodedItem.searchableLevel, .full)
        XCTAssertEqual(encodedItem.searchPassphrase, "hello")
        XCTAssertEqual(encodedItem.userDescription, description)
        XCTAssertEqual(encodedItem.lockState, .lockedWithNativeSecurity)
        XCTAssertEqual(encodedItem.tags, [])
        XCTAssertEqual(encodedItem.item.codeData?.accountName, "my account name")
        XCTAssertEqual(encodedItem.item.codeData?.issuer, "my issuer")
        XCTAssertEqual(encodedItem.item.codeData?.algorithm, "SHA256")
        XCTAssertEqual(encodedItem.item.codeData?.authType, "totp")
        XCTAssertEqual(encodedItem.item.codeData?.period, 36)
        XCTAssertNil(encodedItem.item.codeData?.counter, "No counter for TOTP")
        XCTAssertEqual(encodedItem.item.codeData?.digits, 8)
        XCTAssertEqual(encodedItem.item.codeData?.secretData, Data(hex: "ababa"))
        XCTAssertEqual(encodedItem.item.codeData?.secretFormat, "BASE_32")
        XCTAssertEqual(encodedItem.tintColor, .init(red: 0.1, green: 0.2, blue: 0.3))
    }

    func test_encode_encodesHOTPCode() {
        let id = Identifier<VaultItem>()
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
        let item = VaultItem(
            metadata: .init(
                id: id,
                created: createdDate,
                updated: updateDate,
                relativeOrder: .min,
                userDescription: description,
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "test",
                lockState: .notLocked,
                color: .init(red: 0.1, green: 0.2, blue: 0.3)
            ),
            item: .otpCode(code)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        XCTAssertEqual(encodedItem.id, id.rawValue)
        XCTAssertEqual(encodedItem.createdDate, createdDate)
        XCTAssertEqual(encodedItem.updatedDate, updateDate)
        XCTAssertEqual(encodedItem.userDescription, description)
        XCTAssertEqual(encodedItem.visibility, .always)
        XCTAssertEqual(encodedItem.searchableLevel, .full)
        XCTAssertEqual(encodedItem.searchPassphrase, "test")
        XCTAssertEqual(encodedItem.relativeOrder, 0)
        XCTAssertEqual(encodedItem.lockState, .notLocked)
        XCTAssertEqual(encodedItem.tags, [])
        XCTAssertEqual(encodedItem.item.codeData?.accountName, "my account name")
        XCTAssertEqual(encodedItem.item.codeData?.issuer, "my issuer")
        XCTAssertEqual(encodedItem.item.codeData?.algorithm, "SHA256")
        XCTAssertEqual(encodedItem.item.codeData?.authType, "hotp")
        XCTAssertEqual(encodedItem.item.codeData?.counter, 69)
        XCTAssertNil(encodedItem.item.codeData?.period, "No period for HOTP")
        XCTAssertEqual(encodedItem.item.codeData?.digits, 8)
        XCTAssertEqual(encodedItem.item.codeData?.secretData, Data(hex: "ababa"))
        XCTAssertEqual(encodedItem.item.codeData?.secretFormat, "BASE_32")
        XCTAssertEqual(encodedItem.tintColor, .init(red: 0.1, green: 0.2, blue: 0.3))
    }

    // MARK: Cases

    func test_encode_missingColor() {
        let sut = makeSUT()

        let code1 = anyOTPVaultItem(color: nil)
        let encoded1 = sut.encode(storedItem: code1)
        XCTAssertNil(encoded1.tintColor, "No encoded color, it should be nil")
    }

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

    private func anyOTPVaultItem(algorithm: OTPAuthAlgorithm = .sha1, color: VaultItemColor? = nil) -> VaultItem {
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
        return VaultItem(
            metadata: .init(
                id: Identifier<VaultItem>(),
                created: Date(),
                updated: Date(),
                relativeOrder: .min,
                userDescription: "any",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                lockState: .notLocked,
                color: color
            ),
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
