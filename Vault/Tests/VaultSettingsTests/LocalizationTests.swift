import Foundation
import TestHelpers
import XCTest
@testable import VaultSettings

final class LocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Settings"
        let bundle = Bundle.module

        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }

    func test_localizedStrings_getsKeyFromTable() {
        let value = localized(key: "TEST_KEY_DONT_CHANGE")

        XCTAssertEqual(value, "TEST_VALUE_DONT_CHANGE")
    }
}
