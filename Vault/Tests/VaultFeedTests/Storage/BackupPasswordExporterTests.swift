import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupPasswordExporterTests: XCTestCase {
    func test_init_hasNoStoreSideEffects() {
        let store = BackupPasswordStoreMock()
        _ = makeSUT(store: store)

        XCTAssertEqual(store.setCallCount, 0)
        XCTAssertEqual(store.fetchPasswordCallCount, 0)
    }

    func test_makeExport_encodesFromStore() throws {
        let keyData = Data(repeating: 0x68, count: 10)
        let saltData = Data(repeating: 0x69, count: 20)
        let examplePassword = BackupPassword(key: keyData, salt: saltData)
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = {
            examplePassword
        }
        let sut = makeSUT(store: store)

        let export = try sut.makeExport()

        let str = try XCTUnwrap(String(data: export, encoding: .utf8))

        XCTAssertEqual(str, """
        {
          "KEY" : "aGhoaGhoaGhoaA==",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "1.0.0"
        }
        """)
    }

    func test_makeExport_throwsIfNoPassword() {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = {
            nil
        }
        let sut = makeSUT(store: store)

        XCTAssertThrowsError(try sut.makeExport())
    }

    func test_makeExport_throwsForStoreError() {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = {
            throw NSError(domain: "any", code: 100)
        }
        let sut = makeSUT(store: store)

        XCTAssertThrowsError(try sut.makeExport())
    }
}

// MARK: - Helpers

extension BackupPasswordExporterTests {
    private func makeSUT(
        store: BackupPasswordStoreMock = BackupPasswordStoreMock()
    ) -> BackupPasswordExporter {
        BackupPasswordExporter(store: store)
    }
}
