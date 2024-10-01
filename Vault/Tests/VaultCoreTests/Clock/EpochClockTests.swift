import Foundation
import Testing
import VaultCore

enum EpochClockTests {
    struct EpochClockImplTests {
        @Test
        func isCurrentTime() {
            let currentTime = Date.now.timeIntervalSince1970
            let sut = EpochClockImpl()

            let difference = abs(currentTime - sut.currentTime)
            #expect(difference < 0.5, "This should be the time as of now")
        }
    }

    struct EpochClockMockTests {
        @Test(arguments: [
            1,
            1234,
            Date.now.timeIntervalSince1970,
        ])
        func isInjectedTime(injectedTime: Double) {
            let sut = EpochClockMock(currentTime: injectedTime)

            #expect(sut.currentTime == injectedTime)
        }
    }
}
