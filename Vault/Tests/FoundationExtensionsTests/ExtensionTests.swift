import Foundation
import FoundationExtensions
import XCTest

final class ExtensionTests: XCTestCase {
    func test_sequence_reducedToSet() {
        XCTAssertEqual(
            Set([1, 2, 3]).reducedToSet(),
            [1, 2, 3]
        )

        XCTAssertEqual(
            [Int]().reducedToSet(),
            []
        )

        XCTAssertEqual(
            [1, 1, 1, 1].reducedToSet(),
            [1]
        )
    }
}
