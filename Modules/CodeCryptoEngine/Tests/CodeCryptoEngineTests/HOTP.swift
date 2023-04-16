@testable import CodeCryptoEngine
import CryptoSwift
import XCTest

extension UInt64 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout.size(ofValue: self))
    }
}

extension Data {
    init(hex: String) {
        self.init([UInt8](hex: hex))
    }

    func asType<T>(_: T.Type) -> T {
        withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            ptr.load(as: T.self)
        }
    }
}

/// "HMAC-based one-time password", a counter-based generator.
///
/// https://en.wikipedia.org/wiki/HMAC-based_one-time_password
struct HOTP {
    let secret: Data
    let digits: Digits
    let algorithm: Algorithm
    private let hmac: HMAC

    enum Algorithm {
        case sha1

        var hmacVariant: HMAC.Variant {
            switch self {
            case .sha1:
                return .sha1
            }
        }
    }

    enum Digits: Int {
        case six = 6

        var floatValue: Float {
            Float(rawValue)
        }

        var moduloValue: UInt32 {
            UInt32(pow(10, floatValue))
        }
    }

    struct CodeGenerationError: Error {}

    init(secret: Data, digits: Digits = .six, algorithm: Algorithm = .sha1) {
        self.secret = secret
        self.digits = digits
        self.algorithm = algorithm
        hmac = HMAC(key: secret.bytes, variant: algorithm.hmacVariant)
    }

    func code(counter: UInt64) throws -> UInt32 {
        let code = try hmacCode(counter: counter)
        let value = try truncatedHMAC(hmacCode: code)
        return value % digits.moduloValue
    }

    private func truncatedHMAC(hmacCode: Data) throws -> UInt32 {
        let offset = Int((hmacCode.last ?? 0x00) & 0x0F)
        let truncatedHMAC = Array(hmacCode[offset ... offset + 3]).reversed()
        return Data(truncatedHMAC).asType(UInt32.self) & 0x7FFF_FFFF
    }

    private func hmacCode(counter: UInt64) throws -> Data {
        let counterBytes = counter.bigEndian.data.bytes
        let bytes = try hmac.authenticate(counterBytes)
        return Data(bytes)
    }
}

final class HOTPTests: XCTestCase {
    func test_bytesGenerationLittleEndian() {
        let data = Data(hex: "ffffffee")
        XCTAssertEqual(data.asType(UInt32.self), 0xEEFF_FFFF)
    }

    func test_generateCode_generatesSixDigitCodesForZeroSeed() throws {
        let data = Data(hex: "0")
        let sut = makeSUT(secret: data, digits: .six)

        try XCTAssertEqual(sut.code(counter: 0), 328_482)
        try XCTAssertEqual(sut.code(counter: 1), 812_658)
        try XCTAssertEqual(sut.code(counter: 2), 073_348)
        try XCTAssertEqual(sut.code(counter: .max), 566_304)
    }

    func test_generateCode_generatesSixDigitCodesForPredeterminedSeed() throws {
        // 12345678901234567890 in Hex
        let data = Data(hex: "3132333435363738393031323334353637383930")
        let sut = makeSUT(secret: data, digits: .six)

        try XCTAssertEqual(sut.code(counter: 0), 755_224)
        try XCTAssertEqual(sut.code(counter: 1), 287_082)
        try XCTAssertEqual(sut.code(counter: 2), 359_152)
        try XCTAssertEqual(sut.code(counter: 3), 969_429)
        try XCTAssertEqual(sut.code(counter: 4), 338_314)
        try XCTAssertEqual(sut.code(counter: 5), 254_676)
        try XCTAssertEqual(sut.code(counter: 6), 287_922)
        try XCTAssertEqual(sut.code(counter: 7), 162_583)
        try XCTAssertEqual(sut.code(counter: 8), 399_871)
        try XCTAssertEqual(sut.code(counter: 9), 520_489)
    }

    // MARK: - Helpers

    private func makeSUT(secret: Data, digits: HOTP.Digits = .six) -> HOTP {
        HOTP(secret: secret, digits: digits)
    }
}
