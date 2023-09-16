import XCTest
@testable import OTPAttribution

final class ThirdPartyLibrariesLoaderTests: XCTestCase {
    func test_load_loadsLibraries() throws {
        let sut = makeSUT()

        let loaded = try sut.load()

        XCTAssertEqual(loaded.count, 5)
        XCTAssertEqual(loaded.first?.name, "SwiftUI-Shimmer")
    }
}

extension ThirdPartyLibrariesLoaderTests {
    private func makeSUT() -> ThirdPartyLibraryLoader {
        ThirdPartyLibraryLoader()
    }
}
