import CoreData
import OTPCore
import OTPFeed
import XCTest

final class CoreDataCodeStoreTests: XCTestCase {
    func test_retrieve_deliversEmptyOnEmptyStore() async throws {
        let sut = try makeSUT()

        let result = try await sut.retrieve()
        XCTAssertEqual(result, [])
    }

    func test_retrieve_hasNoSideEffectsOnEmptyStore() async throws {
        let sut = try makeSUT()

        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1, [])
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2, [])
    }

    func test_retrieve_deliversSingleCodeOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        let code = uniqueCode()
        try await sut.insert(code: code)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.code), [code])
    }

    func test_retrieve_deliversMultipleCodesOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        let codes: [OTPAuthCode] = [uniqueCode(), uniqueCode(), uniqueCode()]
        for code in codes {
            try await sut.insert(code: code)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.code), codes)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        let codes: [OTPAuthCode] = [uniqueCode(), uniqueCode(), uniqueCode()]
        for code in codes {
            try await sut.insert(code: code)
        }

        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1.map(\.code), codes)
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2.map(\.code), codes)
    }

    func test_retrieve_deliversErrorOnRetrievalError() async throws {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = try makeSUT()

        await expectThrows(nsError: anyNSError()) {
            _ = try await sut.retrieve()
        }
    }

    func test_insert_deliversNoErrorOnEmptyStore() async throws {
        let sut = try makeSUT()

        try await sut.insert(code: uniqueCode())
    }

    func test_insert_deliversNoErrorOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        try await sut.insert(code: uniqueCode())
        try await sut.insert(code: uniqueCode())
    }

    func test_insert_doesNotOverrideExactSameEntryAsUsesNewIDToUnique() async throws {
        let sut = try makeSUT()
        let code = uniqueCode()

        try await sut.insert(code: code)
        try await sut.insert(code: code)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.code), [code, code])
    }

    func test_insert_returnsUniqueCodeIDAfterSuccessfulInsert() async throws {
        let sut = try makeSUT()
        let code = uniqueCode()

        var ids = [UUID]()
        for _ in 0 ..< 5 {
            let id = try await sut.insert(code: code)
            ids.append(id)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.id), ids)
    }

    func test_insert_deliversErrorOnInsertionError() async throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()

        let sut = try makeSUT()
        await expectThrows(nsError: anyNSError()) {
            try await sut.insert(code: uniqueCode())
        }
    }
}

// MARK: - Helpers

extension CoreDataCodeStoreTests {
    private func makeSUT(file _: StaticString = #filePath, line _: UInt = #line) throws -> CoreDataCodeStore {
        let sut = try CoreDataCodeStore(storeURL: inMemoryStoreURL())
        return sut
    }

    private func expectThrows(
        nsError expectedError: NSError,
        operation: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await operation()
            XCTFail("Expected to throw \(expectedError) but operation completed successfully", file: file, line: line)
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, expectedError.domain, file: file, line: line)
            XCTAssertEqual(nsError.code, expectedError.code, file: file, line: line)
        }
    }

    private func inMemoryStoreURL() -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }

    private func uniqueCode() -> OTPAuthCode {
        let randomData = Data.random(count: 50)
        return OTPAuthCode(secret: .init(data: randomData, format: .base32), accountName: "Some Account")
    }
}
