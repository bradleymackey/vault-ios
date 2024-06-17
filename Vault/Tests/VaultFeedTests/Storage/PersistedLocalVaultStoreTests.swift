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

    @MainActor
    func test_retrieve_deliversEmptyOnEmptyStore() async throws {
        let sut = try makeSUT()

        let result = try await sut.retrieve()
        XCTAssertEqual(result, [])
    }

    @MainActor
    func test_retrieve_hasNoSideEffectsOnEmptyStore() async throws {
        let sut = try makeSUT()

        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1, [])
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2, [])
    }

    // TODO: finish adding retrieve tests
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
