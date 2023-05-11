import CoreData
import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

final class ManagedOTPCodeDecoderTests: XCTestCase {
    private var persistentContainer: NSPersistentContainer!

    override func setUpWithError() throws {
        super.setUp()

        persistentContainer = try NSPersistentContainer.testContainer(storeName: String(describing: self))
    }

    override func tearDown() {
        persistentContainer = nil

        super.tearDown()
    }

    func test_decodeDigits_decodesToCorrectValue() throws {
        let samples: [OTPAuthDigits: NSNumber] = [
            .six: 6,
            .seven: 7,
            .eight: 8,
        ]
        for (digits, value) in samples {
            let sut = makeSUT()
            let code = makeManagedCode(digits: value)

            let decoded = try sut.decode(code: code)
            XCTAssertEqual(decoded.digits, digits)
        }
    }

    func test_decodeDigits_throwsForInvalidDigits() throws {
        let unsupported: [NSNumber] = [-33, 2, 100, 333_333]
        for value in unsupported {
            let sut = makeSUT()
            let code = makeManagedCode(digits: value)

            XCTAssertThrowsError(try sut.decode(code: code))
        }
    }

    func test_decodeAccountName_decodesExpected() throws {
        let accountName = UUID().uuidString
        let code = makeManagedCode(accountName: accountName)
        let sut = makeSUT()

        let decoded = try sut.decode(code: code)
        XCTAssertEqual(decoded.accountName, accountName)
    }

    func test_decodeIssuer_decodesValueIfExists() throws {
        let issuerName = UUID().uuidString
        let code = makeManagedCode(issuer: issuerName)
        let sut = makeSUT()

        let decoded = try sut.decode(code: code)
        XCTAssertEqual(decoded.issuer, issuerName)
    }

    func test_decodeIssuer_decodesNilIfDoesNotExist() throws {
        let code = makeManagedCode(issuer: nil)
        let sut = makeSUT()

        let decoded = try sut.decode(code: code)
        XCTAssertNil(decoded.issuer)
    }

    func test_decodeType_decodesTOTPWithPeriod() throws {
        let code = makeManagedCode(authType: "totp", period: 69)
        let sut = makeSUT()

        let decoded = try sut.decode(code: code)
        XCTAssertEqual(decoded.type, .totp(period: 69))
    }

    func test_decodeType_totpWithoutPeriodThrows() throws {
        let code = makeManagedCode(authType: "totp", period: nil)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(code: code))
    }

    func test_decodeType_decodesHOTPWithCounter() throws {
        let code = makeManagedCode(authType: "hotp", counter: 69)
        let sut = makeSUT()

        let decoded = try sut.decode(code: code)
        XCTAssertEqual(decoded.type, .hotp(counter: 69))
    }

    func test_decodeType_hotpWithoutCounterThrows() throws {
        let code = makeManagedCode(authType: "hotp", counter: nil)
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(code: code))
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

            let decoded = try sut.decode(code: code)
            XCTAssertEqual(decoded.algorithm, algo)
        }
    }

    func test_decodeAlgorithm_throwsIfAlgorithmUnknown() throws {
        let code = makeManagedCode(algorithm: "OTHER")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(code: code))
    }

    func test_decodeSecret_decodesFormat() throws {
        let expected: [OTPAuthSecret.Format: String] = [
            .base32: "BASE_32",
        ]
        for (format, string) in expected {
            let code = makeManagedCode(secretFormat: string)
            let sut = makeSUT()

            let decoded = try sut.decode(code: code)
            XCTAssertEqual(decoded.secret.format, format)
        }
    }

    func test_decodeSecret_throwsIfFormatIsInvalid() throws {
        let code = makeManagedCode(secretFormat: "INVALID")
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(code: code))
    }

    func test_decodeSecret_decodesEmptyData() throws {
        let code = makeManagedCode(secretData: Data())
        let sut = makeSUT()

        let decoded = try sut.decode(code: code)
        XCTAssertEqual(decoded.secret.data, Data())
    }

    func test_decodeSecret_decodesExistingData() throws {
        let data = Data([0xFF, 0xEE, 0x11, 0x12, 0x13, 0x56])
        let code = makeManagedCode(secretData: data)
        let sut = makeSUT()

        let decoded = try sut.decode(code: code)
        XCTAssertEqual(decoded.secret.data, data)
    }

    // MARK: - Helpers

    private func makeSUT() -> ManagedOTPCodeDecoder {
        ManagedOTPCodeDecoder()
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
    ) -> ManagedOTPCode {
        let code = ManagedOTPCode(context: anyContext())
        code.id = UUID()
        code.accountName = accountName
        code.algorithm = algorithm
        code.authType = authType
        code.counter = counter
        code.digits = digits
        code.issuer = issuer
        code.period = period
        code.secretData = secretData
        code.secretFormat = secretFormat
        return code
    }

    private func anyContext() -> NSManagedObjectContext {
        persistentContainer.viewContext
    }
}
