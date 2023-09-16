import Foundation
import TestHelpers
import XCTest
@testable import OTPFeediOS

final class PresentationLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Feed"
        let bundle = Bundle.module

        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }

    func test_localizedStrings_getsKeyFromTable() {
        let value = localized(key: "TEST_KEY_DONT_CHANGE")

        XCTAssertEqual(value, "TEST_VALUE_DONT_CHANGE")
    }

    func test_localizedStringsSettings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Settings"
        let bundle = Bundle.module

        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }

    func test_localizedStringsSettings_getsKeyFromTable() {
        let value = localizedSettings(key: "TEST_KEY_DONT_CHANGE")

        XCTAssertEqual(value, "TEST_VALUE_DONT_CHANGE")
    }
}
