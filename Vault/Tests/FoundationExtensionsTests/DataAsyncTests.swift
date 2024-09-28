import Foundation
import TestHelpers
import Testing
@testable import FoundationExtensions

struct DataAsyncTests {
    @Test
    func initWithAsyncContentsOfURL_fetchesData() async throws {
        let url = try exampleResourceURL()

        let data = try await Data(asyncContentsOf: url)

        let contents = try #require(String(data: data, encoding: .utf8))
        #expect(contents == "Test contents\n")
    }
}

extension DataAsyncTests {
    private func exampleResourceURL() throws -> URL {
        let url = Bundle.module.url(forResource: "TestFile", withExtension: "txt")
        return try #require(url)
    }
}
