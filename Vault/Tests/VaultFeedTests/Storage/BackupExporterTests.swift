import Foundation
import TestHelpers
import VaultBackup
import XCTest
@testable import VaultFeed

final class BackupExporterTests: XCTestCase {
    func test_createEncryptedBackup_usesDifferentIVEachIteration() throws {
        let password = BackupPassword(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let sut = BackupExporter(clock: .init(makeCurrentTime: { 100 }), backupPassword: password)

        var seenData = Set<Data>()
        for _ in 1 ... 100 {
            let payload = VaultApplicationPayload(userDescription: "my backup", items: [], tags: [])
            let backup = try sut.createEncryptedBackup(payload: payload)
            defer { seenData.insert(backup.data) }

            XCTAssertFalse(
                seenData.contains(backup.data),
                "A random IV and/or padding should be used each time, resulting in different encrypted payloads"
            )
        }
    }

    func test_createEncryptedBackup_createsBackupWithNoItems() throws {
        let salt = Data.random(count: 32)
        let password = BackupPassword(key: .random(), salt: salt, keyDervier: .testing)
        let sut = BackupExporter(clock: .init(makeCurrentTime: { 100 }), backupPassword: password)

        let payload = VaultApplicationPayload(userDescription: "my backup", items: [], tags: [])
        let backup = try sut.createEncryptedBackup(payload: payload)

        XCTAssertEqual(backup.encryptionIV.count, 32)
        XCTAssertEqual(backup.keygenSalt, salt)
        XCTAssertEqual(backup.keygenSignature, .testing)
        XCTAssertEqual(backup.version, "1.0.0")
    }

    func test_createEncryptedBackup_createsBackupWithSomeItems() throws {
        let salt = Data.random(count: 32)
        let password = BackupPassword(key: .random(), salt: salt, keyDervier: .testing)
        let sut = BackupExporter(clock: .init(makeCurrentTime: { 100 }), backupPassword: password)

        let payload = VaultApplicationPayload(
            userDescription: "my backup",
            items: [uniqueVaultItem()],
            tags: [VaultItemTag(id: .init(id: UUID()), name: "tag")]
        )
        let backup = try sut.createEncryptedBackup(payload: payload)

        XCTAssertEqual(backup.encryptionIV.count, 32)
        XCTAssertEqual(backup.keygenSalt, salt)
        XCTAssertEqual(backup.keygenSignature, .testing)
        XCTAssertEqual(backup.version, "1.0.0")
    }
}
