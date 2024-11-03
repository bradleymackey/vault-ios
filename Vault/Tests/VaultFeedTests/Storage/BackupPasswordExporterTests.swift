import Foundation
import TestHelpers
import VaultKeygen
import XCTest
@testable import VaultFeed

final class BackupPasswordExporterTests: XCTestCase {
    @MainActor
    func test_makeExport_encodesFromStore() async throws {
        let saltData = Data(repeating: 0x69, count: 20)
        let examplePassword = DerivedEncryptionKey(key: .repeating(byte: 0x68), salt: saltData, keyDervier: .testing)
        let sut = makeSUT(backupPassword: examplePassword)

        let export = try await sut.makeExport()

        let str = try XCTUnwrap(String(data: export, encoding: .utf8))

        XCTAssertEqual(str, """
        {
          "KEY" : "aGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGg=",
          "KEY_DERIVER" : "vault.keygen.testing",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "1.0.0"
        }
        """)
    }
}

// MARK: - Helpers

extension BackupPasswordExporterTests {
    @MainActor
    private func makeSUT(
        backupPassword: DerivedEncryptionKey
    ) -> BackupPasswordExporter {
        BackupPasswordExporter(backupPassword: backupPassword)
    }
}
