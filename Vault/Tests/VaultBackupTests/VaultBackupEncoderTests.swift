import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultBackup

final class VaultBackupEncoderTests: XCTestCase {
    func test_createExportPayload_setsCreatedDateFromCurrentClockTime() {
        let clock = EpochClock(makeCurrentTime: { 1_234_567 })
        let sut = makeSUT(clock: clock)

        let payload = sut.createExportPayload(items: [], userDescription: "")

        XCTAssertEqual(payload.created, Date(timeIntervalSince1970: 1_234_567))
    }

    func test_createExportPayload_setsUserDescriptionFromParameter() {
        let sut = makeSUT()

        let payload = sut.createExportPayload(items: [], userDescription: "hello world")

        XCTAssertEqual(payload.userDescription, "hello world")
    }
}

// MARK: - Helpers

extension VaultBackupEncoderTests {
    private func makeSUT(clock: EpochClock = anyClock()) -> VaultBackupEncoder {
        VaultBackupEncoder(clock: clock)
    }
}

private func anyClock() -> EpochClock {
    EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 })
}
