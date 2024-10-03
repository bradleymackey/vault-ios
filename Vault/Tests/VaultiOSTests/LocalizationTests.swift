import Foundation
import TestHelpers
import Testing
@testable import VaultiOS

struct PresentationLocalizationTests {
    @Test
    func localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        expectLocalizedKeyAndValuesExist(in: .module, "Feed")
    }

    @Test
    func localizedStrings_getsKeyFromTable() {
        let value = localized(key: "TEST_KEY_DONT_CHANGE")
        #expect(value == "TEST_VALUE_DONT_CHANGE")
    }
}
