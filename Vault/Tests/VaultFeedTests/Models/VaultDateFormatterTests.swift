import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class VaultDateFormatterTests: XCTestCase {
    func test_formatForFileName_usesDashesInTime() {
        let sut = VaultDateFormatter(timezone: .gmt)

        let date = Date(timeIntervalSince1970: 1_724_486_168)
        let name = sut.formatForFileName(date: date)

        XCTAssertEqual(name, "2024-08-24T07-56-08.000Z")
    }

    func test_formatForFileName_repectsTimezone() throws {
        func string(timezone: TimeZone) -> String {
            let sut = VaultDateFormatter(timezone: timezone)

            let date = Date(timeIntervalSince1970: 1_724_486_168)
            return sut.formatForFileName(date: date)
        }

        XCTAssertEqual(string(timezone: .gmt), "2024-08-24T07-56-08.000Z")
        let zone1 = try XCTUnwrap(TimeZone(identifier: "America/Mazatlan"))
        XCTAssertEqual(string(timezone: zone1), "2024-08-24T00-56-08.000-07-00")
        let zone2 = try XCTUnwrap(TimeZone(identifier: "America/Toronto"))
        XCTAssertEqual(string(timezone: zone2), "2024-08-24T03-56-08.000-04-00")
        let zone3 = try XCTUnwrap(TimeZone(identifier: "Europe/Warsaw"))
        XCTAssertEqual(string(timezone: zone3), "2024-08-24T09-56-08.000+02-00")
    }
}
