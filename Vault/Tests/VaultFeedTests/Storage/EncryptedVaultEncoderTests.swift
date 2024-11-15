import Foundation
import TestHelpers
import Testing
import VaultBackup
import VaultKeygen
@testable import VaultFeed

struct EncryptedVaultEncoderTests {
    @Test
    func encryptAndEncode_usesDifferentIVEachIteration() throws {
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let sut = EncryptedVaultEncoder(clock: EpochClockMock(currentTime: 100), backupPassword: password)

        var seenData = Set<Data>()
        for _ in 1 ... 100 {
            let payload = VaultApplicationPayload(userDescription: "my backup", items: [], tags: [])
            let backup = try sut.encryptAndEncode(payload: payload)
            defer { seenData.insert(backup.data) }

            #expect(
                seenData.contains(backup.data) == false,
                "A random IV and/or padding should be used each time, resulting in different encrypted payloads"
            )
        }
    }

    @Test
    func encryptAndEncode_createsBackupWithNoItems() throws {
        let salt = Data.random(count: 32)
        let password = DerivedEncryptionKey(key: .random(), salt: salt, keyDervier: .testing)
        let sut = EncryptedVaultEncoder(clock: EpochClockMock(currentTime: 100), backupPassword: password)

        let payload = VaultApplicationPayload(userDescription: "my backup", items: [], tags: [])
        let backup = try sut.encryptAndEncode(payload: payload)

        #expect(backup.encryptionIV.count == 32)
        #expect(backup.keygenSalt == salt)
        #expect(backup.keygenSignature == "vault.keygen.testing")
        #expect(backup.version == "1.0.0")
    }

    @Test
    func encryptAndEncode_createsBackupWithSomeItems() throws {
        let salt = Data.random(count: 32)
        let password = DerivedEncryptionKey(key: .random(), salt: salt, keyDervier: .testing)
        let sut = EncryptedVaultEncoder(clock: EpochClockMock(currentTime: 100), backupPassword: password)

        let payload = VaultApplicationPayload(
            userDescription: "my backup",
            items: [uniqueVaultItem()],
            tags: [VaultItemTag(id: .init(id: UUID()), name: "tag")]
        )
        let backup = try sut.encryptAndEncode(payload: payload)

        #expect(backup.encryptionIV.count == 32)
        #expect(backup.keygenSalt == salt)
        #expect(backup.keygenSignature == "vault.keygen.testing")
        #expect(backup.version == "1.0.0")
    }
}
