import FoundationExtensions
import XCTest
@testable import VaultSettings

final class ThirdPartyLibrariesLoaderTests: XCTestCase {
    func test_load_loadsLibrariesFileFromRealDiskFile() throws {
        let fetcher = FileSystemLocalResourceFetcher()
        let sut = makeSUT(resourceFetcher: fetcher)

        let loaded = try sut.load()

        XCTAssertEqual(loaded.count, 6)
        XCTAssertEqual(loaded.first?.name, "SwiftUI-Shimmer")
    }

    func test_load_parsesValuesCorrectly() throws {
        let exampleFile = """
        {
            "libraries": [
                {
                    "name": "First",
                    "url": "https://github.com/first/first",
                    "licence": "My First Licence"
                },
                {
                    "name": "Second",
                    "url": "https://github.com/second/second",
                    "licence": "My Second Licence"
                },
            ]
        }
        """
        let fetcher = StubLocalResourceFetcher(stubData: Data(exampleFile.utf8))
        let sut = makeSUT(resourceFetcher: fetcher)

        let loaded = try sut.load()

        XCTAssertEqual(loaded.map(\.name), ["First", "Second"])
        XCTAssertEqual(loaded.map(\.licence), ["My First Licence", "My Second Licence"])
        XCTAssertEqual(
            loaded.map(\.url.absoluteString),
            ["https://github.com/first/first", "https://github.com/second/second"]
        )
    }
}

extension ThirdPartyLibrariesLoaderTests {
    private func makeSUT(resourceFetcher: LocalResourceFetcher) -> ThirdPartyLibraryLoader {
        ThirdPartyLibraryLoader(resourceFetcher: resourceFetcher)
    }
}
