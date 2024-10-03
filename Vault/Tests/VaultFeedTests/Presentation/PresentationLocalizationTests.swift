import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

struct PresentationLocalizationTests {
    @Test
    func localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        expectLocalizedKeyAndValuesExist(in: .module, "VaultFeed")
    }

    @Test
    func localizedStrings_getsKeyFromTable() {
        let value = localized(key: "TEST_KEY_DONT_CHANGE")
        #expect(value == "TEST_VALUE_DONT_CHANGE")
    }
}
