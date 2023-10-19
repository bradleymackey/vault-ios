import Foundation
import FoundationExtensions
import XCTest

final class DataRandomTests: XCTestCase {
    func test_random_producesZeroBytes() {
        let sut = Data.random(count: 0)

        XCTAssertTrue(sut.isEmpty)
    }

    func test_random_producesGivenNumberOfBytes() {
        let sut = Data.random(count: 100)

        XCTAssertEqual(sut.count, 100)
    }
}
