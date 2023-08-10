import XCTest
@testable import Attribution

final class ThirdPartyLibrariesLoaderTests: XCTestCase {
    func test_load_loadsLibraries() throws {
        let sut = makeSUT()

        let loaded = try sut.load()

        XCTAssertEqual(loaded.count, 4)
        XCTAssertEqual(loaded.first?.name, "SwiftUI-Shimmer")
        XCTAssertEqual(loaded.last?.name, "ViewInspector 🕵️‍♂️ for SwiftUI")
    }
}

extension ThirdPartyLibrariesLoaderTests {
    private func makeSUT() -> ThirdPartyLibraryLoader {
        ThirdPartyLibraryLoader()
    }
}
