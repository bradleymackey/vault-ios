import Foundation
import SwiftData
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class PersistedLocalVaultStoreTests: XCTestCase {
    @MainActor
    func test_init_createsStoreForTestingWithoutError() throws {
        _ = try makeSUT()
    }
}

// MARK: - Helpers

extension PersistedLocalVaultStoreTests {
    @MainActor
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> PersistedLocalVaultStore {
        let sut = try PersistedLocalVaultStore(storeURL: inMemoryStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func inMemoryStoreURL() -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
}
