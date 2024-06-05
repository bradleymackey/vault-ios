import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupPasswordImporterTests: XCTestCase {
    func test_init_hasNoStoreSideEffects() {
        let store = BackupPasswordStoreMock()
        _ = makeSUT(store: store)

        XCTAssertEqual(store.setCallCount, 0)
        XCTAssertEqual(store.fetchPasswordCallCount, 0)
    }

    func test_import_throwsErrorIfVersionImcompatible() {
        let store = BackupPasswordStoreMock()
        let sut = makeSUT(store: store)

        let export = BackupPasswordExport(version: "0.0.0", key: Data(), salt: Data())

        XCTAssertThrowsError(try sut.importAndOverridePassword(from: export))
    }

    func test_import_setsPasswordForValidData() throws {
        let keyData = Data(repeating: 0x33, count: 10)
        let saltData = Data(repeating: 0x34, count: 10)
        let store = BackupPasswordStoreMock()
        let sut = makeSUT(store: store)

        let export = BackupPasswordExport(version: "1.0.0", key: keyData, salt: saltData)

        try sut.importAndOverridePassword(from: export)

        XCTAssertEqual(store.setArgValues, [BackupPassword(key: keyData, salt: saltData)])
    }

    func test_import_throwsErrorForStoreError() {
        let store = BackupPasswordStoreMock()
        store.setHandler = { _ in
            throw NSError(domain: "any", code: 100)
        }
        let sut = makeSUT(store: store)

        let export = BackupPasswordExport(version: "0.0.0", key: Data(), salt: Data())

        XCTAssertThrowsError(try sut.importAndOverridePassword(from: export))
    }
}

// MARK: - Helpers

extension BackupPasswordImporterTests {
    private func makeSUT(
        store: BackupPasswordStoreMock = BackupPasswordStoreMock()
    ) -> BackupPasswordImporter {
        BackupPasswordImporter(store: store)
    }
}
