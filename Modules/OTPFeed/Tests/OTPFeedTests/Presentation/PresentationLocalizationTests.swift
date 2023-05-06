import Foundation
import XCTest
@testable import OTPFeed

final class PresentationLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "OTPFeed"
        let bundle = Bundle.module

        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }

    func test_localizedStrings_getsKeyFromTable() {
        let value = localized(key: "TEST_KEY_DONT_CHANGE")

        XCTAssertEqual(value, "TEST_VALUE_DONT_CHANGE")
    }
}
