import Foundation
import TestHelpers
import Testing
@testable import VaultBackup

struct IntermediateEncodedVaultEncoderTests {
    let sut = IntermediateEncodedVaultEncoder()

    @Test
    func encodeVault_encodesToJSONFormat_emptyVault() throws {
        let date = Date(timeIntervalSince1970: 12345)
        let backup = anyBackupPayload(
            created: date,
            userDescription: "my description",
            items: []
        )

        let encodedVault = try sut.encode(vaultBackup: backup)

        let decompressedData = try (encodedVault.data as NSData).decompressed(using: .lzma) as Data
        let encoded = try #require(String(data: decompressedData, encoding: .utf8))
        assertSnapshot(of: encoded, as: .lines)
    }

    @Test
    func encodeVault_encodesToJSONFormat_topLevelTags() throws {
        let uuid1 = try #require(UUID(uuidString: "A5950174-2106-4251-BD73-58B8D39F77F3"))
        let uuid2 = try #require(UUID(uuidString: "DCABE94A-C194-49AA-B709-7221DAD253AB"))
        let date = Date(timeIntervalSince1970: 12345)
        let backup = anyBackupPayload(
            created: date,
            userDescription: "my description",
            tags: [
                .init(id: uuid1, title: "My first tag", color: nil, iconName: nil),
                .init(
                    id: uuid2,
                    title: "my second tag",
                    color: .init(red: 0.3, green: 0.4, blue: 0.5),
                    iconName: "some_name"
                ),
            ],
            items: []
        )

        let encodedVault = try sut.encode(vaultBackup: backup)

        let decompressedData = try (encodedVault.data as NSData).decompressed(using: .lzma) as Data
        let encoded = try #require(String(data: decompressedData, encoding: .utf8))
        assertSnapshot(of: encoded, as: .lines)
    }

    @Test
    func encodeVault_encodesToJSONFormat_secureNote() throws {
        let date = Date(timeIntervalSince1970: 12345)
        let uuid1 = try #require(UUID(uuidString: "A5950174-2106-4251-BD73-58B8D39F77F3"))
        let uuid2 = try #require(UUID(uuidString: "DCABE94A-C194-49AA-B709-7221DAD253AB"))
        let item = VaultBackupItem(
            id: uuid1,
            createdDate: date,
            updatedDate: date.addingTimeInterval(7000),
            relativeOrder: 1000,
            userDescription: "",
            tags: [uuid2],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: "passphrase",
            lockState: .notLocked,
            tintColor: .init(red: 0.1, green: 0.2, blue: 0.3),
            item: .note(data: .init(title: "Example Note", rawContents: "Example note", format: .markdown))
        )
        let backup = anyBackupPayload(
            created: date,
            userDescription: "Example vault with a single note",
            items: [item]
        )

        let encodedVault = try sut.encode(vaultBackup: backup)

        let decompressedData = try (encodedVault.data as NSData).decompressed(using: .lzma) as Data
        let encoded = try #require(String(data: decompressedData, encoding: .utf8))
        assertSnapshot(of: encoded, as: .lines)
    }

    @Test
    func encodeVault_encodesToJSONFormat_otpCode() throws {
        let date = Date(timeIntervalSince1970: 12345)
        let uuid = try #require(UUID(uuidString: "A5950174-2106-4251-BD73-58B8D39F77F3"))
        let uuid2 = try #require(UUID(uuidString: "5738B828-FDE4-4F8C-8D4D-FF619054E98E"))
        let item = VaultBackupItem(
            id: uuid,
            createdDate: date,
            updatedDate: date.addingTimeInterval(100),
            relativeOrder: 999,
            userDescription: "",
            tags: [uuid2],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: "pass",
            lockState: .lockedWithNativeSecurity,
            tintColor: .init(red: 0.1, green: 0.2, blue: 0.3),
            item: .otp(data: .init(
                secretFormat: "any",
                secretData: Data(repeating: 0x41, count: 20),
                authType: "authtype",
                period: 123,
                counter: 456,
                algorithm: "algo",
                digits: 789,
                accountName: "acc",
                issuer: "iss"
            ))
        )

        let backup = anyBackupPayload(
            created: date,
            userDescription: "Example vault with a single otp code",
            items: [item]
        )

        let encodedVault = try sut.encode(vaultBackup: backup)

        let decompressedData = try (encodedVault.data as NSData).decompressed(using: .lzma) as Data
        let encoded = try #require(String(data: decompressedData, encoding: .utf8))
        assertSnapshot(of: encoded, as: .lines)
    }

    @Test
    func encodeVault_encodesToJSONFormat_nonEmptyVault() throws {
        let date1 = Date(timeIntervalSince1970: 12345)
        let uuid1 = try #require(UUID(uuidString: "A5950174-2106-4251-BD73-58B8D39F77F3"))
        let item1 = VaultBackupItem(
            id: uuid1,
            createdDate: date1,
            updatedDate: date1.addingTimeInterval(1234),
            relativeOrder: .min,
            userDescription: "",
            tags: [],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: "searchphrase",
            lockState: .notLocked,
            item: .note(data: .init(title: "Hello world", rawContents: "contents of note", format: .plain))
        )
        let date2 = Date(timeIntervalSince1970: 45658)
        let uuid2 = try #require(UUID(uuidString: "29808EAD-3727-4FF6-9B01-C5506BBDC409"))
        let uuidTag = try #require(UUID(uuidString: "493DF342-E537-4722-B6DC-6430A1413E34"))
        let item2 = VaultBackupItem(
            id: uuid2,
            createdDate: date2,
            updatedDate: date2.addingTimeInterval(1234),
            relativeOrder: 666,
            userDescription: "",
            tags: [uuidTag],
            visibility: .always,
            searchableLevel: .none,
            lockState: .lockedWithNativeSecurity,
            item: .note(data: .init(title: "Hello world again", rawContents: "contents", format: .markdown))
        )
        let date3 = Date(timeIntervalSince1970: 345_652_348)
        let uuid3 = try #require(UUID(uuidString: "EF0849B7-C070-491B-A31B-51A11AEA26F4"))
        let item3 = VaultBackupItem(
            id: uuid3,
            createdDate: date3,
            updatedDate: date3.addingTimeInterval(100),
            relativeOrder: 9999,
            userDescription: "",
            tags: [uuidTag],
            visibility: .onlySearch,
            searchableLevel: .onlyTitle,
            lockState: .notLocked,
            tintColor: .init(red: 0.1, green: 0.2, blue: 0.3),
            item: .otp(data: .init(
                secretFormat: "any",
                secretData: Data(repeating: 0xFE, count: 20),
                authType: "authtype",
                period: 123,
                counter: 456,
                algorithm: "algo",
                digits: 789,
                accountName: "acc",
                issuer: "iss"
            ))
        )
        let backup = anyBackupPayload(
            created: date1,
            userDescription: "my description again",
            items: [item1, item2, item3]
        )

        let encodedVault = try sut.encode(vaultBackup: backup)

        let decompressedData = try (encodedVault.data as NSData).decompressed(using: .lzma) as Data
        let encoded = try #require(String(data: decompressedData, encoding: .utf8))
        assertSnapshot(of: encoded, as: .lines)
    }
}

// MARK: - Helpers

extension IntermediateEncodedVaultEncoderTests {
    private func anyBackupPayload(
        created: Date = Date(),
        userDescription: String = "my description",
        tags: [VaultBackupTag] = [],
        items: [VaultBackupItem] = []
    ) -> VaultBackupPayload {
        VaultBackupPayload(
            version: "1.0.0",
            created: created,
            userDescription: userDescription,
            tags: tags,
            items: items,
            obfuscationPadding: Data(hex: "abababa")
        )
    }
}
