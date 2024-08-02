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

        let color = VaultItemColor(red: 0.1, green: 0.3, blue: 0.4)
        let sut = OTPCodeDetailEdits(
            hydratedFromCode: code,
            relativeOrder: 1234,
            userDescription: "mydesc",
            color: color,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .lockedWithNativeSecurity
        )

        XCTAssertEqual(sut.codeType, .totp)
        XCTAssertEqual(sut.totpPeriodLength, 1234)
        XCTAssertEqual(sut.hotpCounterValue, 0, "Defaults HOTP to default for TOTP code")
        XCTAssertEqual(sut.algorithm, .sha1)
        XCTAssertEqual(sut.numberOfDigits, 6)
        XCTAssertEqual(sut.issuerTitle, "myiss")
        XCTAssertEqual(sut.accountNameTitle, "myacc")
        XCTAssertEqual(sut.description, "mydesc")
        XCTAssertEqual(sut.color, color)
        XCTAssertEqual(sut.secretBase32String, "V6X27LY=")
        XCTAssertEqual(sut.viewConfig, .alwaysVisible)
        XCTAssertEqual(sut.lockState, .lockedWithNativeSecurity)
        XCTAssertEqual(sut.relativeOrder, 1234)
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

        let color = VaultItemColor(red: 0.1, green: 0.3, blue: 0.4)
        let sut = OTPCodeDetailEdits(
            hydratedFromCode: code,
            relativeOrder: 4321,
            userDescription: "mydesc2",
            color: color,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .lockedWithNativeSecurity
        )

        XCTAssertEqual(sut.codeType, .hotp)
        XCTAssertEqual(sut.totpPeriodLength, 30, "Defaults TOTP to default for HOTP code")
        XCTAssertEqual(sut.hotpCounterValue, 12345)
        XCTAssertEqual(sut.algorithm, .sha256)
        XCTAssertEqual(sut.numberOfDigits, 6)
        XCTAssertEqual(sut.issuerTitle, "myiss2")
        XCTAssertEqual(sut.accountNameTitle, "myacc2")
        XCTAssertEqual(sut.description, "mydesc2")
        XCTAssertEqual(sut.color, color)
        XCTAssertEqual(sut.secretBase32String, "V6X27LY=")
        XCTAssertEqual(sut.viewConfig, .alwaysVisible)
        XCTAssertEqual(sut.lockState, .lockedWithNativeSecurity)
        XCTAssertEqual(sut.relativeOrder, 4321)
    }

    func test_init_emptySecretIsEmptySecretBase32String() {
        let code = anyOTPAuthCode(secret: .empty())

        let sut = OTPCodeDetailEdits(
            hydratedFromCode: code,
            relativeOrder: .max,
            userDescription: "mydesc",
            color: nil,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked
        )

        XCTAssertEqual(sut.secretBase32String, "")
    }

    func test_isValid_validSecretIsValid() throws {
        let code = anyOTPAuthCode(secret: makeExampleSecret())

        let sut = OTPCodeDetailEdits(
            hydratedFromCode: code,
            relativeOrder: .max,
            userDescription: "mydesc2",
            color: nil,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked
        )

        XCTAssertTrue(sut.isValid)
    }

    func test_isValid_invalidForEmptySecret() throws {
        var sut = OTPCodeDetailEdits.new()
        sut.secretBase32String = ""

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_invalidForEmptyIssuer() throws {
        var sut = OTPCodeDetailEdits.new()
        sut.issuerTitle = ""

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_invalidSecretIsInvalid() throws {
        var sut = OTPCodeDetailEdits.new()
        sut.secretBase32String = "A" // this is invalid

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_invalidForEmptyPassphrase() throws {
        var sut = OTPCodeDetailEdits.new()
        sut.searchPassphrase = ""
        sut.viewConfig = .requiresSearchPassphrase

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_validForNonEmptyPassphrase() throws {
        var sut = OTPCodeDetailEdits.new()
        sut.secretBase32String = "AA"
        sut.issuerTitle = "any"
        sut.searchPassphrase = "passphrase"
        sut.viewConfig = .requiresSearchPassphrase

        XCTAssertTrue(sut.isValid)
    }

    func test_asOTPAuthCode_createsTOTPCode() throws {
        let code = anyTOTPAuthCode()
        let sut = OTPCodeDetailEdits(
            hydratedFromCode: code,
            relativeOrder: .max,
            userDescription: "mydesc",
            color: nil,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked
        )

        let newCode = try sut.asOTPAuthCode()

        XCTAssertEqual(code, newCode)
    }

    func test_asOTPAuthCode_createsHOTPCode() throws {
        let code = anyHOTPAuthCode()
        let sut = OTPCodeDetailEdits(
            hydratedFromCode: code,
            relativeOrder: .max,
            userDescription: "mydesc2",
            color: nil,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked
        )

        let newCode = try sut.asOTPAuthCode()

        XCTAssertEqual(code, newCode)
    }

    func test_asOTPAuthCode_throwsErrorIfBase32SecretIsInvalid() throws {
        var sut = OTPCodeDetailEdits.new()
        sut.secretBase32String = "e~~"

        XCTAssertThrowsError(try sut.asOTPAuthCode())
    }

    func test_isHiddenWithPassphrase_falseIfAlwaysVisible() {
        var sut = OTPCodeDetailEdits.new()
        sut.viewConfig = .alwaysVisible
        XCTAssertFalse(sut.isHiddenWithPassphrase)

        sut.isHiddenWithPassphrase = false
        XCTAssertEqual(sut.viewConfig, .alwaysVisible)
    }

    func test_isHiddenWithPassphrase_trueIfRequiresPassphrase() {
        var sut = OTPCodeDetailEdits.new()
        sut.viewConfig = .requiresSearchPassphrase
        XCTAssertTrue(sut.isHiddenWithPassphrase)

        sut.isHiddenWithPassphrase = true
        XCTAssertEqual(sut.viewConfig, .requiresSearchPassphrase)
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
