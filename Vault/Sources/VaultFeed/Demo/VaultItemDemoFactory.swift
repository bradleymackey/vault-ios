import Foundation
import VaultCore

public struct VaultItemDemoFactory {
    public init() {}

    public func makeTOTPCode() -> VaultItem.Write {
        let randomAccountName = "Peter \(UUID().uuidString.prefix(10))"
        let code = OTPAuthCode(type: .totp(period: 30), data: .init(secret: .empty(), accountName: randomAccountName))
        return VaultItem.Write(
            relativeOrder: 0,
            userDescription: "This is a demo TOTP code",
            color: nil,
            item: .otpCode(code),
            tags: [],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: nil,
            killphrase: nil,
            lockState: .notLocked
        )
    }

    public func makeHOTPCode() -> VaultItem.Write {
        let randomAccountName = "Tommy \(UUID().uuidString.prefix(10))"
        let code = OTPAuthCode(type: .totp(period: 30), data: .init(secret: .empty(), accountName: randomAccountName))
        return VaultItem.Write(
            relativeOrder: 0,
            userDescription: "This is a demo HOTP code",
            color: nil,
            item: .otpCode(code),
            tags: [],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: nil,
            killphrase: nil,
            lockState: .notLocked
        )
    }

    public func makeSecureNote() -> VaultItem.Write {
        let note = SecureNote(
            title: "Hi there",
            contents: "This is a test \(UUID().uuidString.prefix(12))",
            format: .plain
        )
        return VaultItem.Write(
            relativeOrder: 0,
            userDescription: "This is a demo HOTP code",
            color: nil,
            item: .secureNote(note),
            tags: [],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: nil,
            killphrase: nil,
            lockState: .notLocked
        )
    }

    public func makeEncryptedSecureNote() throws -> VaultItem.Write {
        let note = SecureNote(
            title: "Hi there",
            contents: "This is a test \(UUID().uuidString.prefix(12))",
            format: .plain
        )
        let derived = try VaultKeyDeriver.Item.Fast.v1.createEncryptionKey(password: "hello")
        let encryptor = VaultItemEncryptor(key: derived)
        let encrypted = try encryptor.encrypt(item: note)
        return VaultItem.Write(
            relativeOrder: 0,
            userDescription: "",
            color: nil,
            item: .encryptedItem(encrypted),
            tags: [],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: nil,
            killphrase: nil,
            lockState: .notLocked
        )
    }
}
