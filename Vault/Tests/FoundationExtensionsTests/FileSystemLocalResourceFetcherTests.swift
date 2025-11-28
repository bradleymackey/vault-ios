import Foundation
import TestHelpers
import Testing
@testable import FoundationExtensions

struct FileSystemLocalResourceFetcherTests {
    let sut = FileSystemLocalResourceFetcher()

    @Test
    func fetchLocalResourceFromURL_throwsIfResourceIsNotPresentForFileURL() async throws {
        let url = try #require(URL(string: "file:///doesnotexist"))
        await #expect(throws: (any Error).self, performing: {
            try await sut.fetchLocalResource(at: url)
        })
    }

    @Test
    func fetchLocalResourceFromURL_fetchesResourceFromModule() async throws {
        let path = try #require(Bundle.module.path(forResource: "TestFile", ofType: "txt"))
        let url = URL(fileURLWithPath: path)
        let data = try await sut.fetchLocalResource(at: url)

        #expect(data == Data("Test contents\n".utf8))
    }

    @Test(arguments: [Bundle.main, .module])
    func fetchLocalResourceFromBundle_throwsIfFileNotPresentInBundle(bundle: Bundle) async throws {
        await #expect(throws: (any Error).self) {
            try await sut.fetchLocalResource(
                fromBundle: bundle,
                fileName: "doesnotexist",
                fileExtension: "any",
            )
        }
    }

    @Test
    func fetchLocalResourceFromBundle_fetchesDataFromBundle() async throws {
        let response = try await sut.fetchLocalResource(
            fromBundle: .module,
            fileName: "TestFile",
            fileExtension: "txt",
        )
        #expect(response == Data("Test contents\n".utf8))
    }
}

// MARK: - Helpers

extension FileSystemLocalResourceFetcherTests {
    private func makeURL(forBundleFile filename: String, fileExtension: String) throws -> URL {
        let path = try #require(Bundle.module.path(forResource: filename, ofType: fileExtension))
        return URL(fileURLWithPath: path)
    }
}
