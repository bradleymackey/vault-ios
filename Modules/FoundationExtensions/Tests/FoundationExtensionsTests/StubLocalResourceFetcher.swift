import Foundation
import XCTest
@testable import FoundationExtensions

final class StubLocalResourceFetcherTests: XCTestCase {
    func test_fetchLocalResource_fetchesStubbedData() throws {
        let stubData = Data("Hello world".utf8)
        let sut = makeSUT(data: stubData)

        let anyURL = try XCTUnwrap(URL(string: "https://google.com"))
        let response = try sut.fetchLocalResource(at: anyURL)

        XCTAssertEqual(response, stubData)
    }
}

// MARK: - Helpers

extension StubLocalResourceFetcherTests {
    private func makeSUT(data: Data) -> LocalResourceFetcher {
        StubLocalResourceFetcher(stubData: data)
    }
}
