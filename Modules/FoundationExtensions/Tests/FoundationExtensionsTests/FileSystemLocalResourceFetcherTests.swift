import Foundation
import XCTest
@testable import FoundationExtensions

final class FileSystemLocalResourceFetcherTests: XCTestCase {
    func test_fetchLocalResourceFromURL_throwsIfResourceIsNotPresentForFileURL() throws {
        let sut = makeSUT()

        let url = try XCTUnwrap(URL(string: "file:///doesnotexist"))
        XCTAssertThrowsError(try sut.fetchLocalResource(at: url))
    }

    func test_fetchLocalResourceFromURL_fetchesResourceFromModule() throws {
        let sut = makeSUT()

        let path = try XCTUnwrap(Bundle.module.path(forResource: "TestFile", ofType: "txt"))
        let url = URL(fileURLWithPath: path)
        let data = try sut.fetchLocalResource(at: url)

        XCTAssertEqual(data, Data("Test contents\n".utf8))
    }

    func test_fetchLocalResourceFromBundle_throwsIfFileNotPresentInBundle() throws {
        let sut = makeSUT()

        let bundlesToCheck: [Bundle] = [.main, .module]
        for bundle in bundlesToCheck {
            XCTAssertThrowsError(try sut.fetchLocalResource(
                fromBundle: bundle,
                fileName: "doesnotexist",
                fileExtension: "any"
            ))
        }
    }

    func test_fetchLocalResourceFromBundle_fetchesDataFromBundle() throws {
        let sut = makeSUT()

        let response = try sut.fetchLocalResource(
            fromBundle: .module,
            fileName: "TestFile",
            fileExtension: "txt"
        )
        XCTAssertEqual(response, Data("Test contents\n".utf8))
    }
}

// MARK: - Helpers

extension FileSystemLocalResourceFetcherTests {
    private func makeSUT() -> any LocalResourceFetcher {
        FileSystemLocalResourceFetcher()
    }

    private func makeURL(forBundleFile filename: String, fileExtension: String) throws -> URL {
        let path = try XCTUnwrap(Bundle.module.path(forResource: filename, ofType: fileExtension))
        return URL(fileURLWithPath: path)
    }
}
