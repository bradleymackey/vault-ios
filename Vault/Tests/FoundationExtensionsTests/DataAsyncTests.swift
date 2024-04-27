import Foundation
import TestHelpers
import XCTest
@testable import FoundationExtensions

final class DataAsyncTests: XCTestCase {
    func test_initWithAsyncContentsOfURL_fetchesData() async throws {
        let url = try exampleResourceURL()

        let data = try await Data(asyncContentsOf: url)

        let contents = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(contents, "Test contents\n")
    }
}

extension DataAsyncTests {
    private func exampleResourceURL() throws -> URL {
        let url = Bundle.module.url(forResource: "TestFile", withExtension: "txt")
        return try XCTUnwrap(url)
    }
}
