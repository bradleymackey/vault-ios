import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupPasswordExporterTests: XCTestCase {
    @MainActor
    func test_init_hasNoStoreSideEffects() {
        let store = BackupPasswordStoreMock()
        _ = makeSUT(store: store)

        XCTAssertEqual(store.setCallCount, 0)
        XCTAssertEqual(store.fetchPasswordCallCount, 0)
    }

    @MainActor
    func test_makeExport_encodesFromStore() async throws {
        let keyData = Data(repeating: 0x68, count: 10)
        let saltData = Data(repeating: 0x69, count: 20)
        let examplePassword = BackupPassword(key: keyData, salt: saltData, keyDervier: .testing)
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = {
            examplePassword
        }
        let sut = makeSUT(store: store)

        let export = try await sut.makeExport()

        let str = try XCTUnwrap(String(data: export, encoding: .utf8))

        XCTAssertEqual(str, """
        {
          "KEY" : "aGhoaGhoaGhoaA==",
          "KEY_DERIVER" : "vault.keygen.default.testing",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "1.0.0"
        }
        """)
    }

    @MainActor
    func test_makeExport_throwsIfNoPassword() async {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = {
            nil
        }
        let sut = makeSUT(store: store)

        await XCTAssertThrowsError(try await sut.makeExport())
    }

    @MainActor
    func test_makeExport_throwsForStoreError() async {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = {
            throw NSError(domain: "any", code: 100)
        }
        let sut = makeSUT(store: store)

        await XCTAssertThrowsError(try await sut.makeExport())
    }
}

// MARK: - Helpers

extension BackupPasswordExporterTests {
    @MainActor
    private func makeSUT(
        store: BackupPasswordStoreMock = BackupPasswordStoreMock()
    ) -> BackupPasswordExporter {
        BackupPasswordExporter(dataModel: anyVaultDataModel(backupPasswordStore: store))
    }
}
