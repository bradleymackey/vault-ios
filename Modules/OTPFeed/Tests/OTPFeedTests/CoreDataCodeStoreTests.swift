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
        XCTAssertEqual(result, [code])
    }

    func test_retrieve_deliversMultipleCodesOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        let codes: [OTPAuthCode] = [uniqueCode(), uniqueCode(), uniqueCode()]
        for code in codes {
            try await sut.insert(code: code)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result, codes)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        let codes: [OTPAuthCode] = [uniqueCode(), uniqueCode(), uniqueCode()]
        for code in codes {
            try await sut.insert(code: code)
        }

        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1, codes)
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2, codes)
    }

    func test_retrieve_deliversErrorOnRetrievalError() async throws {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = try makeSUT()

        do {
            _ = try await sut.retrieve()
            XCTFail("Expected error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, anyNSError().domain)
            XCTAssertEqual(nsError.code, anyNSError().code)
        }
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

    private func uniqueCode() -> OTPAuthCode {
        let randomData = Data.random(count: 50)
        return OTPAuthCode(secret: .init(data: randomData, format: .base32), accountName: "Some Account")
    }
}

extension Data {
    static func random(count: Int) -> Data {
        var bytes = [UInt8]()
        bytes.reserveCapacity(count)
        for _ in 0 ..< count {
            let nextByte = UInt8.random(in: UInt8.min ... UInt8.max)
            bytes.append(nextByte)
        }
        return Data(bytes)
    }
}
