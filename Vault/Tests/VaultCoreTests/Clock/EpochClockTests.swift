import Combine
import Foundation
import VaultCore
import XCTest

final class EpochClockTests: XCTestCase {
    func test_currentTime_isInjectedCurrentTime() {
        let sut = EpochClockImpl(makeCurrentTime: { 1234 })

        XCTAssertEqual(sut.currentTime, 1234)
    }
}
