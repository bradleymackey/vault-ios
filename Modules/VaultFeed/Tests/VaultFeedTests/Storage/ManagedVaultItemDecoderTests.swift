import CoreData
import Foundation
import VaultCore
import XCTest
@testable import VaultFeed

final class ManagedVaultItemDecoderTests: XCTestCase {
    private var persistentContainer: NSPersistentContainer!

    override func setUpWithError() throws {
        super.setUp()

        persistentContainer = try NSPersistentContainer.testContainer(storeName: String(describing: self))
    }

    override func tearDown() {
        persistentContainer = nil

        super.tearDown()
    }
}

// MARK: - OTP Code

extension ManagedVaultItemDecoderTests {
    func test_decodeDigits_decodesToCorrectValue() throws {
        let samples: [OTPAuthDigits: NSNumber] = [
            OTPAuthDigits(value: 0): 0,
            OTPAuthDigits(value: 6): 6,
            OTPAuthDigits(value: 7): 7,
            OTPAuthDigits(value: 8): 8,
            OTPAuthDigits(value: 100): 100,
            OTPAuthDigits(value: 1024): 1024,
        ]
        for (digits, value) in samples {
            let sut = makeSUT()
            let code = makeManagedCode(digits: value)

            let decoded = try sut.decode(item: code)
            XCTAssertEqual(decoded.otpCode?.data.digits, digits)
        }
    }

    func test_decodeDigits_throwsForInvalidDigits() throws {
        let unsupported: [NSNumber] = [-33, 333_333]
        for value in unsupported {
            let sut = makeSUT()
            let code = makeManagedCode(digits: value)

            XCTAssertThrowsError(try sut.decode(item: code))
        }
    }

    func test_decodeAccountName_decodesExpected() throws {
        let accountName = UUID().uuidString
        let code = makeManagedCode(accountName: accountName)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.otpCode?.data.accountName, accountName)
    }

    func test_decodeIssuer_decodesValueIfExists() throws {
        let issuerName = UUID().uuidString
        let code = makeManagedCode(issuer: issuerName)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.otpCode?.data.issuer, issuerName)
    }

    func test_decodeIssuer_decodesNilIfDoesNotExist() throws {
        let code = makeManagedCode(issuer: nil)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertNil(decoded.otpCode?.data.issuer)
    }

    func test_decodeType_decodesTOTPWithPeriod() throws {
        let code = makeManagedCode(authType: "totp", period: 69)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.otpCode?.type, .totp(period: 69))
    }

    func test_decodeType_totpWithoutPeriodThrows() throws {
        let code = makeManagedCode(authType: "totp", period: nil)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: code))
    }

    func test_decodeType_decodesHOTPWithCounter() throws {
        let code = makeManagedCode(authType: "hotp", counter: 69)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.otpCode?.type, .hotp(counter: 69))
    }

    func test_decodeType_hotpWithoutCounterThrows() throws {
        let code = makeManagedCode(authType: "hotp", counter: nil)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: code))
    }

    func test_decodeAlgorithm_decodesValidAlgorithm() throws {
        let expected: [OTPAuthAlgorithm: String] = [
            .sha1: "SHA1",
            .sha256: "SHA256",
            .sha512: "SHA512",
        ]
        for (algo, string) in expected {
            let code = makeManagedCode(algorithm: string)
            let sut = makeSUT()

            let decoded = try sut.decode(item: code)
            XCTAssertEqual(decoded.otpCode?.data.algorithm, algo)
        }
    }

    func test_decodeAlgorithm_throwsIfAlgorithmUnknown() throws {
        let code = makeManagedCode(algorithm: "OTHER")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: code))
    }

    func test_decodeSecret_decodesFormat() throws {
        let expected: [OTPAuthSecret.Format: String] = [
            .base32: "BASE_32",
        ]
        for (format, string) in expected {
            let code = makeManagedCode(secretFormat: string)
            let sut = makeSUT()

            let decoded = try sut.decode(item: code)
            XCTAssertEqual(decoded.otpCode?.data.secret.format, format)
        }
    }

    func test_decodeSecret_throwsIfFormatIsInvalid() throws {
        let code = makeManagedCode(secretFormat: "INVALID")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(item: code))
    }

    func test_decodeSecret_decodesEmptyData() throws {
        let code = makeManagedCode(secretData: Data())
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.otpCode?.data.secret.data, Data())
    }

    func test_decodeSecret_decodesExistingData() throws {
        let data = Data([0xFF, 0xEE, 0x11, 0x12, 0x13, 0x56])
        let code = makeManagedCode(secretData: data)
        let sut = makeSUT()

        let decoded = try sut.decode(item: code)
        XCTAssertEqual(decoded.otpCode?.data.secret.data, data)
    }
}

// MARK: - Helpers

extension ManagedVaultItemDecoderTests {
    private func makeSUT() -> ManagedVaultItemDecoder {
        ManagedVaultItemDecoder()
    }

    private func makeManagedCode(
        accountName: String = "any",
        algorithm: String = "SHA1",
        authType: String = "totp",
        counter: NSNumber? = UInt32(30) as NSNumber,
        digits: NSNumber = UInt32(6) as NSNumber,
        issuer: String? = "issuer",
        period: NSNumber? = UInt32(30) as NSNumber,
        secretData: Data = Data(),
        secretFormat: String = "BASE_32"
    ) -> ManagedVaultItem {
        let context = anyContext()
        let code = ManagedVaultItem(context: context)
        code.id = UUID()

        let otp = ManagedOTPDetails(context: context)
        otp.accountName = accountName
        otp.algorithm = algorithm
        otp.authType = authType
        otp.counter = counter
        otp.digits = digits
        otp.issuer = issuer
        otp.period = period
        otp.secretData = secretData
        otp.secretFormat = secretFormat

        code.otpDetails = otp
        return code
    }

    private func anyContext() -> NSManagedObjectContext {
        persistentContainer.viewContext
    }
}
