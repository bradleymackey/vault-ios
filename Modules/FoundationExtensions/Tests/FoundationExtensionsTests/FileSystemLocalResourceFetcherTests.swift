import Foundation
import XCTest
@testable import FoundationExtensions

final class FileSystemLocalResourceFetcherTests: XCTestCase {
    func test_fetchLocalResource_throwsIfResourceIsNotPresentForFileURL() throws {
        let sut = makeSUT()

        let url = try XCTUnwrap(URL(string: "file:///doesnotexist"))
        XCTAssertThrowsError(try sut.fetchLocalResource(at: url))
    }

    func test_fetchLocalResource_fetchesResourceFromModule() throws {
        let sut = makeSUT()

        let url = try makeURL(forBundleFile: "TestFile", fileExtension: "txt")
        let data = try sut.fetchLocalResource(at: url)

        XCTAssertEqual(data, Data("Test contents\n".utf8))
    }
}

// MARK: - Helpers

extension FileSystemLocalResourceFetcherTests {
    private func makeSUT() -> LocalResourceFetcher {
        FileSystemLocalResourceFetcher()
    }

    private func makeURL(forBundleFile filename: String, fileExtension: String) throws -> URL {
        let path = try XCTUnwrap(Bundle.module.path(forResource: filename, ofType: fileExtension))
        return URL(fileURLWithPath: path)
    }
}
