import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultFeed

final class BackupEventLoggerImplTests: XCTestCase {
    func test_init_hasNoSideEffects() throws {
        let defaults = try testUserDefaults()
        let beforeKeys = defaults.keys
        _ = makeSUT(defaults: defaults)

        XCTAssertEqual(beforeKeys, defaults.keys)
    }

    func test_lastBackupEvent_isNilIfNoBackup() throws {
        let defaults = try testUserDefaults()
        let sut = makeSUT(defaults: defaults)

        let backup = sut.lastBackupEvent()

        XCTAssertNil(backup)
    }

    func test_lastBackup_getsStoredBackup() throws {
        let defaults = try testUserDefaults()
        let clock = EpochClock(makeCurrentTime: { 100 })
        let sut = makeSUT(defaults: defaults, clock: clock)
        let date = Date(timeIntervalSince1970: 1234)
        sut.exportedToPDF(date: date, hash: .init(value: Data(hex: "1234")))

        let backup = sut.lastBackupEvent()

        XCTAssertEqual(backup?.backupDate, clock.currentDate)
        XCTAssertEqual(backup?.eventDate, date)
        XCTAssertEqual(backup?.payloadHash, .init(value: Data(hex: "1234")))
        XCTAssertEqual(backup?.kind, .exportedToPDF)
    }

    func test_exportedToPDF_savesToDefaults() throws {
        let defaults = try testUserDefaults()
        let beforeKeys = defaults.keys
        let sut = makeSUT(defaults: defaults)
        let date = Date(timeIntervalSince1970: 1234)

        sut.exportedToPDF(date: date, hash: .init(value: Data(hex: "1234")))

        XCTAssertEqual(beforeKeys.symmetricDifference(defaults.keys), ["vault.backup.last-event"])
    }
}

// MARK: - Helpers

extension BackupEventLoggerImplTests {
    private func makeSUT(
        defaults: UserDefaults,
        clock: EpochClock = .init(makeCurrentTime: { 100 })
    ) -> BackupEventLoggerImpl {
        BackupEventLoggerImpl(defaults: .init(userDefaults: defaults), clock: clock)
    }
}
