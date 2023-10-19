import Foundation
import VaultCore
import XCTest

final class OTPAuthDigitsTests: XCTestCase {
    func test_description_encodesToSimpleDigits() {
        let digits = OTPAuthDigits(value: 123)

        XCTAssertEqual("\(digits)", "123")
    }
}
