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
}

// MARK: - Helpers

extension BackupPasswordExporterTests {
    private func makeSUT(
        store: BackupPasswordStoreMock = BackupPasswordStoreMock()
    ) -> BackupPasswordExporter {
        BackupPasswordExporter(store: store)
    }
}
