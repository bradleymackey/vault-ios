import Combine
import Foundation
import VaultCore
import XCTest

final class EpochClockTests: XCTestCase {
    func test_impl_isCurrentTime() {
        let currentTime = Date.now.timeIntervalSince1970
        let sut = EpochClockImpl()

        XCTAssertEqual(currentTime, sut.currentTime, accuracy: 10)
    }

    func test_mock_isInjectedTime() {
        let sut = EpochClockMock(currentTime: 1234)

        XCTAssertEqual(sut.currentTime, 1234)
    }

    func test_iso8601_formatting() {
        let sut = EpochClockMock(currentTime: 1234)

        XCTAssertEqual(sut.iso8601, "1970-01-01T00:20:34Z")
    }
}
