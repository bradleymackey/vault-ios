import Foundation
import XCTest

extension XCTestCase {
    func expectAllIdentical(
        in array: [some AnyObject],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            array.allSatisfy { $0 === array.first },
            "All items are not identical instances",
            file: file,
            line: line
        )
    }
}
