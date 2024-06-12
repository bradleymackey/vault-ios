import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupPasswordImporterImplTests: XCTestCase {
    func test_init_hasNoStoreSideEffects() {
        let store = BackupPasswordStoreMock()
        _ = makeSUT(store: store)

        XCTAssertEqual(store.setCallCount, 0)
        XCTAssertEqual(store.fetchPasswordCallCount, 0)
    }

    func test_import_throwsErrorIfVersionImcompatible() {
        let store = BackupPasswordStoreMock()
        let sut = makeSUT(store: store)

        let export = Data("""
        {
          "KEY" : "aGhoaGhoaGhoaA==",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "0.0.0"
        }
        """.utf8)

        XCTAssertThrowsError(try sut.importAndOverridePassword(from: export))
    }

    func test_import_setsPasswordForValidData() throws {
        let store = BackupPasswordStoreMock()
        let sut = makeSUT(store: store)

        let export = Data("""
        {
          "KEY" : "aGhoaGhoaGhoaA==",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "1.0.0"
        }
        """.utf8)
        try sut.importAndOverridePassword(from: export)

        let keyData = Data(repeating: 0x68, count: 10)
        let saltData = Data(repeating: 0x69, count: 20)
        XCTAssertEqual(store.setArgValues, [BackupPassword(key: keyData, salt: saltData)])
    }

    func test_import_throwsErrorForStoreError() {
        let store = BackupPasswordStoreMock()
        store.setHandler = { _ in
            throw NSError(domain: "any", code: 100)
        }
        let sut = makeSUT(store: store)

        let export = Data("""
        {
          "KEY" : "aGhoaGhoaGhoaA==",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "1.0.0"
        }
        """.utf8)

        XCTAssertThrowsError(try sut.importAndOverridePassword(from: export))
    }
}

// MARK: - Helpers

extension BackupPasswordImporterImplTests {
    private func makeSUT(
        store: BackupPasswordStoreMock = BackupPasswordStoreMock()
    ) -> BackupPasswordImporterImpl {
        BackupPasswordImporterImpl(store: store)
    }
}
