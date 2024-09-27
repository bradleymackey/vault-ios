import Foundation
import Testing
@testable import FoundationExtensions

struct StubLocalResourceFetcherTests {
    @Test
    func fetchLocalResourceFromURL_fetchesStubbedData() async throws {
        let stubData = Data("Hello world".utf8)
        let sut = makeSUT(data: stubData)

        let anyURL = try #require(URL(string: "https://google.com"))
        let response = try await sut.fetchLocalResource(at: anyURL)

        #expect(response == stubData)
    }

    @Test(arguments: [Bundle.main, .module])
    func fetchLocalResourceFromBundle_fetchesStubbedData(bundle: Bundle) async throws {
        let stubData = Data("Hello world".utf8)
        let sut = makeSUT(data: stubData)

        let response = try await sut.fetchLocalResource(
            fromBundle: bundle,
            fileName: "any",
            fileExtension: "any"
        )
        #expect(response == stubData)
    }
}

// MARK: - Helpers

extension StubLocalResourceFetcherTests {
    private func makeSUT(data: Data) -> any LocalResourceFetcher {
        StubLocalResourceFetcher(stubData: data)
    }
}
