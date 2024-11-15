import Foundation
import FoundationExtensions
import TestHelpers
import Testing
import VaultBackup
import VaultCore
@testable import VaultFeed

final class VaultBackupItemEncoderTests {
    // MARK: Full items

    @Test
    func encode_encodesNote() {
        let id = Identifier<VaultItem>()
        let createdDate = Date(timeIntervalSince1970: 123_456)
        let updateDate = Date(timeIntervalSince1970: 456_789)
        let description = "my user description"
        let note = SecureNote(title: "title", contents: "contents", format: .markdown)
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
                searchPassphrase: "searchme",
                killphrase: "killme",
                lockState: .notLocked,
                color: .init(red: 0.1, green: 0.2, blue: 0.3)
            ),
            item: .secureNote(note)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        #expect(encodedItem.id == id.rawValue)
        #expect(encodedItem.createdDate == createdDate)
        #expect(encodedItem.updatedDate == updateDate)
        #expect(encodedItem.userDescription == description)
        #expect(encodedItem.tags == tags.reducedToSet(\.id))
        #expect(encodedItem.relativeOrder == 999_995)
        #expect(encodedItem.item.noteData?.title == "title")
        #expect(encodedItem.item.noteData?.rawContents == "contents")
        #expect(encodedItem.item.noteData?.format == .markdown)
        #expect(encodedItem.visibility == .always)
        #expect(encodedItem.searchableLevel == .onlyTitle)
        #expect(encodedItem.searchPassphrase == "searchme")
        #expect(encodedItem.killphrase == "killme")
        #expect(encodedItem.lockState == .notLocked)
        #expect(encodedItem.tintColor == .init(red: 0.1, green: 0.2, blue: 0.3))

        #expect(encodedItem.item.encryptedData == nil)
        #expect(encodedItem.item.codeData == nil)
    }

    @Test
    func encode_encodesEncryptedItem() {
        let id = Identifier<VaultItem>()
        let createdDate = Date(timeIntervalSince1970: 123_456)
        let updateDate = Date(timeIntervalSince1970: 456_789)
        let description = "my user description"
        let itemData = Data.random(count: 12)
        let itemAuthentication = Data.random(count: 12)
        let itemEncryptionIV = Data.random(count: 12)
        let itemKeygenSalt = Data.random(count: 12)
        let itemSignature = "this is sig"
        let encryptedItem = EncryptedItem(
            version: "1.0.2",
            title: "this nice",
            data: itemData,
            authentication: itemAuthentication,
            encryptionIV: itemEncryptionIV,
            keygenSalt: itemKeygenSalt,
            keygenSignature: itemSignature
        )
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
                searchPassphrase: "searchme",
                killphrase: "killmenow",
                lockState: .notLocked,
                color: .init(red: 0.1, green: 0.2, blue: 0.3)
            ),
            item: .encryptedItem(encryptedItem)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        #expect(encodedItem.id == id.rawValue)
        #expect(encodedItem.createdDate == createdDate)
        #expect(encodedItem.updatedDate == updateDate)
        #expect(encodedItem.userDescription == description)
        #expect(encodedItem.tags == tags.reducedToSet(\.id))
        #expect(encodedItem.relativeOrder == 999_995)
        #expect(encodedItem.item.encryptedData?.version == "1.0.2")
        #expect(encodedItem.item.encryptedData?.title == "this nice")
        #expect(encodedItem.item.encryptedData?.data == itemData)
        #expect(encodedItem.item.encryptedData?.authentication == itemAuthentication)
        #expect(encodedItem.item.encryptedData?.encryptionIV == itemEncryptionIV)
        #expect(encodedItem.item.encryptedData?.keygenSalt == itemKeygenSalt)
        #expect(encodedItem.item.encryptedData?.keygenSignature == itemSignature)
        #expect(encodedItem.visibility == .always)
        #expect(encodedItem.searchableLevel == .onlyTitle)
        #expect(encodedItem.searchPassphrase == "searchme")
        #expect(encodedItem.killphrase == "killmenow")
        #expect(encodedItem.lockState == .notLocked)
        #expect(encodedItem.tintColor == .init(red: 0.1, green: 0.2, blue: 0.3))

        #expect(encodedItem.item.noteData == nil)
        #expect(encodedItem.item.codeData == nil)
    }

    @Test
    func encode_encodesTOTPCode() {
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
                killphrase: "killme",
                lockState: .lockedWithNativeSecurity,
                color: .init(red: 0.1, green: 0.2, blue: 0.3)
            ),
            item: .otpCode(code)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        #expect(encodedItem.id == id.rawValue)
        #expect(encodedItem.createdDate == createdDate)
        #expect(encodedItem.updatedDate == updateDate)
        #expect(encodedItem.relativeOrder == 1234)
        #expect(encodedItem.visibility == .always)
        #expect(encodedItem.searchableLevel == .full)
        #expect(encodedItem.searchPassphrase == "hello")
        #expect(encodedItem.killphrase == "killme")
        #expect(encodedItem.userDescription == description)
        #expect(encodedItem.lockState == .lockedWithNativeSecurity)
        #expect(encodedItem.tags == [])
        #expect(encodedItem.item.codeData?.accountName == "my account name")
        #expect(encodedItem.item.codeData?.issuer == "my issuer")
        #expect(encodedItem.item.codeData?.algorithm == "SHA256")
        #expect(encodedItem.item.codeData?.authType == "totp")
        #expect(encodedItem.item.codeData?.period == 36)
        #expect(encodedItem.item.codeData?.counter == nil, "No counter for TOTP")
        #expect(encodedItem.item.codeData?.digits == 8)
        #expect(encodedItem.item.codeData?.secretData == Data(hex: "ababa"))
        #expect(encodedItem.item.codeData?.secretFormat == "BASE_32")
        #expect(encodedItem.tintColor == .init(red: 0.1, green: 0.2, blue: 0.3))

        #expect(encodedItem.item.encryptedData == nil)
        #expect(encodedItem.item.noteData == nil)
    }

    @Test
    func encode_encodesHOTPCode() {
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
                killphrase: "killme",
                lockState: .notLocked,
                color: .init(red: 0.1, green: 0.2, blue: 0.3)
            ),
            item: .otpCode(code)
        )
        let sut = makeSUT()

        let encodedItem = sut.encode(storedItem: item)

        #expect(encodedItem.id == id.rawValue)
        #expect(encodedItem.createdDate == createdDate)
        #expect(encodedItem.updatedDate == updateDate)
        #expect(encodedItem.userDescription == description)
        #expect(encodedItem.visibility == .always)
        #expect(encodedItem.searchableLevel == .full)
        #expect(encodedItem.searchPassphrase == "test")
        #expect(encodedItem.killphrase == "killme")
        #expect(encodedItem.relativeOrder == .min)
        #expect(encodedItem.lockState == .notLocked)
        #expect(encodedItem.tags == [])
        #expect(encodedItem.item.codeData?.accountName == "my account name")
        #expect(encodedItem.item.codeData?.issuer == "my issuer")
        #expect(encodedItem.item.codeData?.algorithm == "SHA256")
        #expect(encodedItem.item.codeData?.authType == "hotp")
        #expect(encodedItem.item.codeData?.counter == 69)
        #expect(encodedItem.item.codeData?.period == nil, "No period for HOTP")
        #expect(encodedItem.item.codeData?.digits == 8)
        #expect(encodedItem.item.codeData?.secretData == Data(hex: "ababa"))
        #expect(encodedItem.item.codeData?.secretFormat == "BASE_32")
        #expect(encodedItem.tintColor == .init(red: 0.1, green: 0.2, blue: 0.3))

        #expect(encodedItem.item.encryptedData == nil)
        #expect(encodedItem.item.noteData == nil)
    }

    // MARK: Cases

    @Test
    func encode_missingColor() {
        let sut = makeSUT()

        let code1 = anyOTPAuthCode().wrapInAnyVaultItem(color: nil)
        let encoded1 = sut.encode(storedItem: code1)
        #expect(encoded1.tintColor == nil, "No encoded color, it should be nil")
    }

    @Test
    func encode_otpAlgorithmTypes() {
        let sut = makeSUT()

        let code1 = anyOTPAuthCode(algorithm: .sha1).wrapInAnyVaultItem()
        let encoded1 = sut.encode(storedItem: code1)
        #expect(encoded1.item.codeData?.algorithm == "SHA1")

        let code2 = anyOTPAuthCode(algorithm: .sha256).wrapInAnyVaultItem()
        let encoded2 = sut.encode(storedItem: code2)
        #expect(encoded2.item.codeData?.algorithm == "SHA256")

        let code3 = anyOTPAuthCode(algorithm: .sha512).wrapInAnyVaultItem()
        let encoded3 = sut.encode(storedItem: code3)
        #expect(encoded3.item.codeData?.algorithm == "SHA512")
    }
}

// MARK: - Helpers

extension VaultBackupItemEncoderTests {
    private func makeSUT() -> VaultBackupItemEncoder {
        VaultBackupItemEncoder()
    }
}

extension VaultBackupItem.Item {
    fileprivate var noteData: VaultBackupItem.Note? {
        switch self {
        case let .note(note): note
        default: nil
        }
    }

    fileprivate var encryptedData: VaultBackupItem.Encrypted? {
        switch self {
        case let .encrypted(data): data
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
