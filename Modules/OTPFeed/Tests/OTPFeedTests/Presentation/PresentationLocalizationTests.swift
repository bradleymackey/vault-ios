import Foundation
import XCTest
@testable import OTPFeed

final class PresentationLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "OTPFeed"
        let bundle = Bundle.module

        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }
}
