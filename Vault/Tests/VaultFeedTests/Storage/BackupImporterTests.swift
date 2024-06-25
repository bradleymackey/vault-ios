import Foundation
import TestHelpers
import VaultBackup
import XCTest
@testable import VaultFeed

final class BackupImporterTests: XCTestCase {
    func test_importEncryptedBackup_decodesWithNoItems() throws {
        let password = BackupPassword(key: .random(count: 32), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(password: password, description: "my backup", items: [], tags: [])
        let sut = makeSUT(password: password)

        let decoded = try sut.importEncryptedBackup(encryptedVault: encryptedBackup)

        XCTAssertEqual(decoded.items, [])
        XCTAssertEqual(decoded.tags, [])
        XCTAssertEqual(decoded.userDescription, "my backup")
    }

    func test_importEncryptedBackup_decodesWithItems() throws {
        let item1 = searchableStoredOTPVaultItem()
        let tag1 = VaultItemTag(id: .init(id: UUID()), name: "tag1")
        let tag2 = VaultItemTag(id: .init(id: UUID()), name: "tag2")
        let password = BackupPassword(key: .random(count: 32), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(
            password: password,
            description: "my backup description",
            items: [item1],
            tags: [tag1, tag2]
        )
        let sut = makeSUT(password: password)

        let decoded = try sut.importEncryptedBackup(encryptedVault: encryptedBackup)

        XCTAssertEqual(decoded.items.map(\.id), [item1].map(\.id))
        XCTAssertEqual(decoded.tags, [tag1, tag2])
        XCTAssertEqual(decoded.userDescription, "my backup description")
    }
}

// MARK: - Helpers

extension BackupImporterTests {
    private func makeSUT(password: BackupPassword) -> BackupImporter {
        BackupImporter(backupPassword: password)
    }

    private func makeEncryptedVault(
        password: BackupPassword,
        description: String = "any",
        items: [VaultItem] = [],
        tags: [VaultItemTag] = []
    ) throws -> EncryptedVault {
        let exporter = BackupExporter(clock: .init(makeCurrentTime: { 100 }), backupPassword: password)
        let payload = VaultApplicationPayload(userDescription: description, items: items, tags: tags)
        let encryptedBackup = try exporter.createEncryptedBackup(payload: payload)
        return encryptedBackup
    }
}
