import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultFeed

final class OTPCodeDetailEditsTests: XCTestCase {
    func test_initHydratedFromCode_assignsTOTPCodeType() {
        let code = OTPAuthCode(
            type: .totp(period: 1234),
            data: .init(
                secret: makeExampleSecret(),
                algorithm: .sha1,
                digits: .default,
                accountName: "myacc",
                issuer: "myiss"
            )
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
        XCTAssertEqual(sut.secretBase32String, "V6X27LY=")
    }

    func test_initHydratedFromCode_assignsHOTPCodeType() {
        let code = OTPAuthCode(
            type: .hotp(counter: 12345),
            data: .init(
                secret: makeExampleSecret(),
                algorithm: .sha256,
                digits: .default,
                accountName: "myacc2",
                issuer: "myiss2"
            )
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
        XCTAssertEqual(sut.secretBase32String, "V6X27LY=")
    }

    func test_init_emptySecretIsEmptySecretBase32String() {
        let code = anyOTPAuthCode(secret: .empty())

        let sut = OTPCodeDetailEdits(hydratedFromCode: code, userDescription: "mydesc")

        XCTAssertEqual(sut.secretBase32String, "")
    }

    func test_isValid_validSecretIsValid() throws {
        let code = OTPAuthCode(
            type: .hotp(counter: 12345),
            data: .init(
                secret: makeExampleSecret(),
                algorithm: .sha256,
                digits: .default,
                accountName: "myacc2",
                issuer: "myiss2"
            )
        )

        let sut = OTPCodeDetailEdits(hydratedFromCode: code, userDescription: "mydesc2")

        XCTAssertTrue(sut.isValid)
    }

    func test_isValid_invalidSecretIsInvalid() throws {
        let code = OTPAuthCode(
            type: .hotp(counter: 12345),
            data: .init(
                secret: makeExampleSecret(),
                algorithm: .sha256,
                digits: .default,
                accountName: "myacc2",
                issuer: "myiss2"
            )
        )

        var sut = OTPCodeDetailEdits(hydratedFromCode: code, userDescription: "mydesc2")
        sut.secretBase32String = "A" // this is invalid

        XCTAssertFalse(sut.isValid)
    }

    func test_asOTPAuthCode_createsTOTPCode() throws {
        let code = anyTOTPAuthCode()
        let sut = OTPCodeDetailEdits(hydratedFromCode: code, userDescription: "mydesc")

        let newCode = try sut.asOTPAuthCode()

        XCTAssertEqual(code, newCode)
    }

    func test_asOTPAuthCode_createsHOTPCode() throws {
        let code = anyHOTPAuthCode()
        let sut = OTPCodeDetailEdits(hydratedFromCode: code, userDescription: "mydesc2")

        let newCode = try sut.asOTPAuthCode()

        XCTAssertEqual(code, newCode)
    }

    func test_asOTPAuthCode_throwsErrorIfBase32SecretIsInvalid() throws {
        var sut = OTPCodeDetailEdits(hydratedFromCode: anyTOTPAuthCode(), userDescription: "any")
        sut.secretBase32String = "e~~"

        XCTAssertThrowsError(try sut.asOTPAuthCode())
    }
}

// MARK: - Helpers

extension OTPCodeDetailEditsTests {
    private func makeExampleSecret() -> OTPAuthSecret {
        OTPAuthSecret(data: Data(hex: "afafafaf"), format: .base32)
    }

    private func anyOTPAuthCode(secret: OTPAuthSecret) -> OTPAuthCode {
        OTPAuthCode(
            type: .totp(period: 1234),
            data: .init(secret: secret, algorithm: .sha1, digits: .default, accountName: "myacc", issuer: "myiss")
        )
    }

    private func anyTOTPAuthCode() -> OTPAuthCode {
        OTPAuthCode(
            type: .totp(period: 1234),
            data: .init(
                secret: makeExampleSecret(),
                algorithm: .sha1,
                digits: .default,
                accountName: "myacc",
                issuer: "myiss"
            )
        )
    }

    private func anyHOTPAuthCode() -> OTPAuthCode {
        OTPAuthCode(
            type: .hotp(counter: 12345),
            data: .init(
                secret: makeExampleSecret(),
                algorithm: .sha256,
                digits: .default,
                accountName: "myacc2",
                issuer: "myiss2"
            )
        )
    }
}
