import CoreData
import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

struct ManagedOTPCodeDecoder {
    func decode(code: ManagedOTPCode) throws -> OTPAuthCode {
        try OTPAuthCode(
            type: decodeType(code: code),
            secret: .empty(),
            digits: decode(digits: code.digits),
            accountName: code.accountName,
            issuer: code.issuer
        )
    }

    enum DecodingError: Error {
        case badDigits(NSNumber)
        case invalidType
        case missingPeriodForTOTP
        case missingCounterForHOTP
    }

    private func decode(digits: NSNumber) throws -> OTPAuthDigits {
        if let digits = OTPAuthDigits(rawValue: digits.intValue) {
            return digits
        } else {
            throw DecodingError.badDigits(digits)
        }
    }

    private func decodeType(code: ManagedOTPCode) throws -> OTPAuthType {
        switch code.authType {
        case "totp":
            guard let period = code.period?.uint32Value else {
                throw DecodingError.missingPeriodForTOTP
            }
            return .totp(period: period)
        case "hotp":
            guard let counter = code.counter?.uint32Value else {
                throw DecodingError.missingCounterForHOTP
            }
            return .hotp(counter: counter)
        default:
            throw DecodingError.invalidType
        }
    }
}

final class ManagedOTPCodeDecoderTests: XCTestCase {
    private var persistentContainer: NSPersistentContainer!

    override func setUpWithError() throws {
        super.setUp()

        persistentContainer = try NSPersistentContainer.load(
            name: CoreDataCodeStore.modelName,
            model: XCTUnwrap(CoreDataCodeStore.model),
            url: inMemoryStoreURL()
        )
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

    // MARK: - Helpers

    private func makeSUT() -> ManagedOTPCodeDecoder {
        ManagedOTPCodeDecoder()
    }

    private func makeManagedCode(
        accountName: String = "any",
        algorithm: String = "any",
        authType: String = "totp",
        counter: NSNumber? = UInt32(30) as NSNumber,
        digits: NSNumber = UInt32(6) as NSNumber,
        issuer: String? = "issuer",
        period: NSNumber? = UInt32(30) as NSNumber,
        secretData: Data = Data(),
        secretFormat: String = "any"
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

    private func inMemoryStoreURL() -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
}
