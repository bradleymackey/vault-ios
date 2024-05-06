import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultFeed

final class OTPCodeDetailEditsTests: XCTestCase {
    func test_initHydratedFromCode_assignsTOTPCodeType() {
        let code = OTPAuthCode(
            type: .totp(period: 1234),
            data: .init(secret: .empty(), algorithm: .sha1, digits: .default, accountName: "myacc", issuer: "myiss")
        )

        let sut = OTPCodeDetailEdits(hydratedFromCode: code, userDescription: "mydesc")

        XCTAssertEqual(sut.codeType, .totp)
        XCTAssertEqual(sut.totpPeriodLength, 1234)
        XCTAssertEqual(sut.hotpCounterValue, .max, "Defaults HOTP to max for TOTP code")
        XCTAssertEqual(sut.algorithm, .sha1)
        XCTAssertEqual(sut.numberOfDigits, 6)
        XCTAssertEqual(sut.issuerTitle, "myiss")
        XCTAssertEqual(sut.accountNameTitle, "myacc")
        XCTAssertEqual(sut.description, "mydesc")
    }

    func test_initHydratedFromCode_assignsHOTPCodeType() {
        let code = OTPAuthCode(
            type: .hotp(counter: 12345),
            data: .init(secret: .empty(), algorithm: .sha256, digits: .default, accountName: "myacc2", issuer: "myiss2")
        )

        let sut = OTPCodeDetailEdits(hydratedFromCode: code, userDescription: "mydesc2")

        XCTAssertEqual(sut.codeType, .hotp)
        XCTAssertEqual(sut.totpPeriodLength, .max, "Defaults TOTP to max for HOTP code")
        XCTAssertEqual(sut.hotpCounterValue, 12345, "Defaults HOTP to max for TOTP code")
        XCTAssertEqual(sut.algorithm, .sha256)
        XCTAssertEqual(sut.numberOfDigits, 6)
        XCTAssertEqual(sut.issuerTitle, "myiss2")
        XCTAssertEqual(sut.accountNameTitle, "myacc2")
        XCTAssertEqual(sut.description, "mydesc2")
    }

    func test_asOTPAuthCode_createsTOTPCode() {
        let code = OTPAuthCode(
            type: .totp(period: 1234),
            data: .init(secret: .empty(), algorithm: .sha1, digits: .default, accountName: "myacc", issuer: "myiss")
        )
        let sut = OTPCodeDetailEdits(hydratedFromCode: code, userDescription: "mydesc")

        let newCode = sut.asOTPAuthCode()

        XCTAssertEqual(code, newCode)
    }

    func test_asOTPAuthCode_createsHOTPCode() {
        let code = OTPAuthCode(
            type: .hotp(counter: 12345),
            data: .init(secret: .empty(), algorithm: .sha256, digits: .default, accountName: "myacc2", issuer: "myiss2")
        )
        let sut = OTPCodeDetailEdits(hydratedFromCode: code, userDescription: "mydesc2")

        let newCode = sut.asOTPAuthCode()

        XCTAssertEqual(code, newCode)
    }
}
