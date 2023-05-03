import CoreData
import OTPFeed
import XCTest

final class CoreDataCodeStoreTests: XCTestCase {
    func test_retrieve_deliversEmptyOnEmptyCache() async throws {
        let sut = try makeSUT()

        let result = try await sut.retrieve()
        XCTAssertEqual(result, [])
    }
}

// MARK: - Helpers

extension CoreDataCodeStoreTests {
    private func makeSUT(file _: StaticString = #filePath, line _: UInt = #line) throws -> CoreDataCodeStore {
        let sut = try CoreDataCodeStore(storeURL: inMemoryStoreURL())
        return sut
    }

    private func inMemoryStoreURL() -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
}
