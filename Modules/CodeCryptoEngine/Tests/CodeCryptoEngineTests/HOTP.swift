import XCTest
@testable import CodeCryptoEngine

final class HOTPTests: XCTestCase {
    func test_bytesGenerationLittleEndian() {
        let data = Data(hex: "ffffffee")
        XCTAssertEqual(data.asType(UInt32.self), 0xEEFF_FFFF)
    }

    func test_verify_trueIfEqualToGeneratedSeed() throws {
        let sut = makeSUT(secret: zeroSecret)

        let actualCode = try sut.code(counter: 1234)
        try XCTAssertTrue(sut.verify(counter: 1234, value: actualCode))
    }

    func test_verify_falseIfNotEqualToGeneratedSeed() throws {
        let sut = makeSUT(secret: zeroSecret)

        let actualCode = try sut.code(counter: 1234)
        let notActualCode = actualCode + 1
        try XCTAssertFalse(sut.verify(counter: 1234, value: notActualCode))
    }

    func test_code_generatesSHA1SixDigitCodesForZeroSeed() throws {
        let sut = makeSUT(secret: zeroSecret, digits: .six, algorithm: .sha1)

        try XCTAssertEqual(sut.code(counter: 0), 328_482)
        try XCTAssertEqual(sut.code(counter: 1), 812_658)
        try XCTAssertEqual(sut.code(counter: 2), 073_348)
        try XCTAssertEqual(sut.code(counter: 3), 887_919)
        try XCTAssertEqual(sut.code(counter: 4), 320_986)
        try XCTAssertEqual(sut.code(counter: 5), 435_986)
        try XCTAssertEqual(sut.code(counter: 6), 964_213)
        try XCTAssertEqual(sut.code(counter: 7), 267_638)
        try XCTAssertEqual(sut.code(counter: 8), 985_814)
        try XCTAssertEqual(sut.code(counter: 9), 003_773)
        try XCTAssertEqual(sut.code(counter: .max), 566_304)
    }

    func test_code_generatesSHA1SixDigitCodes() throws {
        let sut = makeSUT(secret: rfcSecret, digits: .six, algorithm: .sha1)

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
        try XCTAssertEqual(sut.code(counter: .max), 094_451)
    }

    func test_code_generatesSHA1SevenDigitCodes() throws {
        let sut = makeSUT(secret: rfcSecret, digits: .seven, algorithm: .sha1)

        try XCTAssertEqual(sut.code(counter: 0), 4_755_224)
        try XCTAssertEqual(sut.code(counter: 1), 4_287_082)
        try XCTAssertEqual(sut.code(counter: 2), 7_359_152)
        try XCTAssertEqual(sut.code(counter: 3), 6_969_429)
        try XCTAssertEqual(sut.code(counter: 4), 338_314)
        try XCTAssertEqual(sut.code(counter: 5), 8_254_676)
        try XCTAssertEqual(sut.code(counter: 6), 8_287_922)
        try XCTAssertEqual(sut.code(counter: 7), 2_162_583)
        try XCTAssertEqual(sut.code(counter: 8), 3_399_871)
        try XCTAssertEqual(sut.code(counter: 9), 5_520_489)
        try XCTAssertEqual(sut.code(counter: .max), 3_094_451)
    }

    func test_code_generatesSHA1EightDigitCodes() throws {
        let sut = makeSUT(secret: rfcSecret, digits: .eight, algorithm: .sha1)

        try XCTAssertEqual(sut.code(counter: 0), 84_755_224)
        try XCTAssertEqual(sut.code(counter: 1), 94_287_082)
        try XCTAssertEqual(sut.code(counter: 2), 37_359_152)
        try XCTAssertEqual(sut.code(counter: 3), 26_969_429)
        try XCTAssertEqual(sut.code(counter: 4), 40_338_314)
        try XCTAssertEqual(sut.code(counter: 5), 68_254_676)
        try XCTAssertEqual(sut.code(counter: 6), 18_287_922)
        try XCTAssertEqual(sut.code(counter: 7), 82_162_583)
        try XCTAssertEqual(sut.code(counter: 8), 73_399_871)
        try XCTAssertEqual(sut.code(counter: 9), 45_520_489)
        try XCTAssertEqual(sut.code(counter: .max), 63_094_451)
    }

    func test_code_generatesSHA256SixDigitCodes() throws {
        let sut = makeSUT(secret: rfcSecret, digits: .six, algorithm: .sha256)

        try XCTAssertEqual(sut.code(counter: 0), 875_740)
        try XCTAssertEqual(sut.code(counter: 1), 247_374)
        try XCTAssertEqual(sut.code(counter: 2), 254_785)
        try XCTAssertEqual(sut.code(counter: 3), 496_144)
        try XCTAssertEqual(sut.code(counter: 4), 480_556)
        try XCTAssertEqual(sut.code(counter: 5), 697_997)
        try XCTAssertEqual(sut.code(counter: 6), 191_609)
        try XCTAssertEqual(sut.code(counter: 7), 579_288)
        try XCTAssertEqual(sut.code(counter: 8), 895_912)
        try XCTAssertEqual(sut.code(counter: 9), 184_989)
        try XCTAssertEqual(sut.code(counter: .max), 790_413)
    }

    func test_code_generatesSHA256SevenDigitCodes() throws {
        let sut = makeSUT(secret: rfcSecret, digits: .seven, algorithm: .sha256)

        try XCTAssertEqual(sut.code(counter: 0), 4_875_740)
        try XCTAssertEqual(sut.code(counter: 1), 2_247_374)
        try XCTAssertEqual(sut.code(counter: 2), 6_254_785)
        try XCTAssertEqual(sut.code(counter: 3), 7_496_144)
        try XCTAssertEqual(sut.code(counter: 4), 5_480_556)
        try XCTAssertEqual(sut.code(counter: 5), 9_697_997)
        try XCTAssertEqual(sut.code(counter: 6), 191_609)
        try XCTAssertEqual(sut.code(counter: 7), 7_579_288)
        try XCTAssertEqual(sut.code(counter: 8), 3_895_912)
        try XCTAssertEqual(sut.code(counter: 9), 3_184_989)
        try XCTAssertEqual(sut.code(counter: .max), 7_790_413)
    }

    func test_code_generatesSHA256EightDigitCodes() throws {
        let sut = makeSUT(secret: rfcSecret, digits: .eight, algorithm: .sha256)

        try XCTAssertEqual(sut.code(counter: 0), 74_875_740)
        try XCTAssertEqual(sut.code(counter: 1), 32_247_374)
        try XCTAssertEqual(sut.code(counter: 2), 66_254_785)
        try XCTAssertEqual(sut.code(counter: 3), 67_496_144)
        try XCTAssertEqual(sut.code(counter: 4), 25_480_556)
        try XCTAssertEqual(sut.code(counter: 5), 89_697_997)
        try XCTAssertEqual(sut.code(counter: 6), 40_191_609)
        try XCTAssertEqual(sut.code(counter: 7), 67_579_288)
        try XCTAssertEqual(sut.code(counter: 8), 83_895_912)
        try XCTAssertEqual(sut.code(counter: 9), 23_184_989)
        try XCTAssertEqual(sut.code(counter: .max), 27_790_413)
    }

    func test_code_generatesSHA512SixDigitCodes() throws {
        let sut = makeSUT(secret: rfcSecret, digits: .six, algorithm: .sha512)

        try XCTAssertEqual(sut.code(counter: 0), 125_165)
        try XCTAssertEqual(sut.code(counter: 1), 342_147)
        try XCTAssertEqual(sut.code(counter: 2), 730_102)
        try XCTAssertEqual(sut.code(counter: 3), 778_726)
        try XCTAssertEqual(sut.code(counter: 4), 937_510)
        try XCTAssertEqual(sut.code(counter: 5), 848_329)
        try XCTAssertEqual(sut.code(counter: 6), 266_680)
        try XCTAssertEqual(sut.code(counter: 7), 588_359)
        try XCTAssertEqual(sut.code(counter: 8), 39399)
        try XCTAssertEqual(sut.code(counter: 9), 643_409)
        try XCTAssertEqual(sut.code(counter: .max), 381_515)
    }

    func test_code_generatesSHA512SevenDigitCodes() throws {
        let sut = makeSUT(secret: rfcSecret, digits: .seven, algorithm: .sha512)

        try XCTAssertEqual(sut.code(counter: 0), 4_125_165)
        try XCTAssertEqual(sut.code(counter: 1), 9_342_147)
        try XCTAssertEqual(sut.code(counter: 2), 1_730_102)
        try XCTAssertEqual(sut.code(counter: 3), 3_778_726)
        try XCTAssertEqual(sut.code(counter: 4), 1_937_510)
        try XCTAssertEqual(sut.code(counter: 5), 6_848_329)
        try XCTAssertEqual(sut.code(counter: 6), 6_266_680)
        try XCTAssertEqual(sut.code(counter: 7), 2_588_359)
        try XCTAssertEqual(sut.code(counter: 8), 5_039_399)
        try XCTAssertEqual(sut.code(counter: 9), 3_643_409)
        try XCTAssertEqual(sut.code(counter: .max), 1_381_515)
    }

    func test_code_generatesSHA512EightDigitCodes() throws {
        let sut = makeSUT(secret: rfcSecret, digits: .eight, algorithm: .sha512)

        try XCTAssertEqual(sut.code(counter: 0), 4_125_165)
        try XCTAssertEqual(sut.code(counter: 1), 69_342_147)
        try XCTAssertEqual(sut.code(counter: 2), 71_730_102)
        try XCTAssertEqual(sut.code(counter: 3), 73_778_726)
        try XCTAssertEqual(sut.code(counter: 4), 81_937_510)
        try XCTAssertEqual(sut.code(counter: 5), 16_848_329)
        try XCTAssertEqual(sut.code(counter: 6), 36_266_680)
        try XCTAssertEqual(sut.code(counter: 7), 22_588_359)
        try XCTAssertEqual(sut.code(counter: 8), 45_039_399)
        try XCTAssertEqual(sut.code(counter: 9), 33_643_409)
        try XCTAssertEqual(sut.code(counter: .max), 11_381_515)
    }

    // MARK: - Helpers

    private func makeSUT(secret: Data, digits: HOTP.Digits = .six, algorithm: HOTP.Algorithm = .sha1) -> HOTP {
        HOTP(secret: secret, digits: digits, algorithm: algorithm)
    }

    private var rfcSecret: Data {
        // 12345678901234567890 in Hex
        Data(hex: "3132333435363738393031323334353637383930")
    }

    private var zeroSecret: Data {
        Data(hex: "0")
    }
}
