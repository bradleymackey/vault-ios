import Foundation
import Testing
import VaultCore

struct OTPAuthDigitsTests {
    @Test
    func description_encodesToSimpleDigits() {
        let digits = OTPAuthDigits(value: 123)

        #expect("\(digits)" == "123")
    }
}
