import Foundation
import XCTest
@testable import FoundationExtensions

final class StubLocalResourceFetcherTests: XCTestCase {
    func test_fetchLocalResourceFromURL_fetchesStubbedData() throws {
        let stubData = Data("Hello world".utf8)
        let sut = makeSUT(data: stubData)

        let anyURL = try XCTUnwrap(URL(string: "https://google.com"))
        let response = try sut.fetchLocalResource(at: anyURL)

        XCTAssertEqual(response, stubData)
    }

    func test_fetchLocalResourceFromBundle_fetchesStubbedData() throws {
        let stubData = Data("Hello world".utf8)
        let sut = makeSUT(data: stubData)

        let bundlesToCheck: [Bundle] = [.main, .module]
        for bundle in bundlesToCheck {
            let response = try sut.fetchLocalResource(
                fromBundle: bundle,
                fileName: "any",
                fileExtension: "any"
            )
            XCTAssertEqual(response, stubData)
        }
    }
}

// MARK: - Helpers

extension StubLocalResourceFetcherTests {
    private func makeSUT(data: Data) -> LocalResourceFetcher {
        StubLocalResourceFetcher(stubData: data)
    }
}
