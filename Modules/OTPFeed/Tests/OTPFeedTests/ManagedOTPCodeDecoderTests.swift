import CoreData
import Foundation
import OTPCore
import XCTest
@testable import OTPFeed

struct ManagedOTPCodeDecoder {
    func decode(code: ManagedOTPCode) throws -> OTPAuthCode {
        try OTPAuthCode(
            secret: .empty(),
            digits: decode(digits: code.digits),
            accountName: code.accountName,
            issuer: code.issuer
        )
    }

    enum DecodingError: Error {
        case badDigits(NSNumber)
    }

    private func decode(digits: NSNumber) throws -> OTPAuthDigits {
        if let digits = OTPAuthDigits(rawValue: digits.intValue) {
            return digits
        } else {
            throw DecodingError.badDigits(digits)
        }
    }
}

final class ManagedOTPCodeDecoderTests: XCTestCase {
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

    // MARK: - Helpers

    private func makeSUT() -> ManagedOTPCodeDecoder {
        ManagedOTPCodeDecoder()
    }

    private func makeManagedCode(
        accountName: String = "any",
        algorithm: String = "any",
        authType: String = "any",
        counter: NSNumber? = 30,
        digits: NSNumber = 6,
        id: UUID = UUID(),
        issuer: String? = "issuer",
        period: NSNumber? = 30,
        secretData: Data = Data(),
        secretFormat: String = "any"
    ) -> ManagedOTPCode {
        let anyContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        let code = ManagedOTPCode(context: anyContext)
        code.accountName = accountName
        code.algorithm = algorithm
        code.authType = authType
        code.counter = counter
        code.digits = digits
        code.id = id
        code.issuer = issuer
        code.period = period
        code.secretData = secretData
        code.secretFormat = secretFormat
        return code
    }
}
