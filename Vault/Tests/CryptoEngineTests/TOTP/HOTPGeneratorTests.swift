import CryptoEngine
import CryptoSwift
import Foundation
import Testing

struct HOTPGeneratorTests {
    @Test
    func verify_trueIfEqualToGeneratedSeed() throws {
        let sut = makeSUT(secret: zeroSecret)

        let actualCode = try sut.code(counter: 1234)
        #expect(try sut.verify(counter: 1234, value: actualCode))
    }

    @Test
    func verify_falseIfNotEqualToGeneratedSeed() throws {
        let sut = makeSUT(secret: zeroSecret)

        let actualCode = try sut.code(counter: 1234)
        let notActualCode = actualCode + 1
        let result = try sut.verify(counter: 1234, value: notActualCode)
        #expect(!result)
    }

    @Test(arguments: [
        (0, 328_482),
        (1, 812_658),
        (2, 073_348),
        (3, 887_919),
        (4, 320_986),
        (5, 435_986),
        (6, 964_213),
        (7, 267_638),
        (8, 985_814),
        (9, 003_773),
        (.max, 566_304),
    ])
    func code_generatesSHA1SixDigitCodesForZeroSeed(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: zeroSecret, digits: 6, algorithm: .sha1)
        #expect(try sut.code(counter: counter) == value)
    }

    @Test(arguments: [
        (0, 755_224),
        (1, 287_082),
        (2, 359_152),
        (3, 969_429),
        (4, 338_314),
        (5, 254_676),
        (6, 287_922),
        (7, 162_583),
        (8, 399_871),
        (9, 520_489),
        (.max, 094_451),
    ])
    func code_generatesSHA1SixDigitCodes(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: OTPRFCSecret.default, digits: 6, algorithm: .sha1)
        #expect(try sut.code(counter: counter) == value)
    }

    @Test(arguments: [
        (0, 4_755_224),
        (1, 4_287_082),
        (2, 7_359_152),
        (3, 6_969_429),
        (4, 338_314),
        (5, 8_254_676),
        (6, 8_287_922),
        (7, 2_162_583),
        (8, 3_399_871),
        (9, 5_520_489),
        (.max, 3_094_451),
    ])
    func code_generatesSHA1SevenDigitCodes(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: OTPRFCSecret.default, digits: 7, algorithm: .sha1)
        #expect(try sut.code(counter: counter) == value)
    }

    @Test(arguments: [
        (0, 84_755_224),
        (1, 94_287_082),
        (2, 37_359_152),
        (3, 26_969_429),
        (4, 40_338_314),
        (5, 68_254_676),
        (6, 18_287_922),
        (7, 82_162_583),
        (8, 73_399_871),
        (9, 45_520_489),
        (.max, 63_094_451),
    ])
    func code_generatesSHA1EightDigitCodes(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: OTPRFCSecret.default, digits: 8, algorithm: .sha1)
        #expect(try sut.code(counter: counter) == value)
    }

    @Test(arguments: [
        (0, 875_740),
        (1, 247_374),
        (2, 254_785),
        (3, 496_144),
        (4, 480_556),
        (5, 697_997),
        (6, 191_609),
        (7, 579_288),
        (8, 895_912),
        (9, 184_989),
        (.max, 790_413),
    ])
    func code_generatesSHA256SixDigitCodes(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: OTPRFCSecret.default, digits: 6, algorithm: .sha256)
        #expect(try sut.code(counter: counter) == value)
    }

    @Test(arguments: [
        (0, 4_875_740),
        (1, 2_247_374),
        (2, 6_254_785),
        (3, 7_496_144),
        (4, 5_480_556),
        (5, 9_697_997),
        (6, 191_609),
        (7, 7_579_288),
        (8, 3_895_912),
        (9, 3_184_989),
        (.max, 7_790_413),
    ])
    func code_generatesSHA256SevenDigitCodes(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: OTPRFCSecret.default, digits: 7, algorithm: .sha256)
        #expect(try sut.code(counter: counter) == value)
    }

    @Test(arguments: [
        (0, 74_875_740),
        (1, 32_247_374),
        (2, 66_254_785),
        (3, 67_496_144),
        (4, 25_480_556),
        (5, 89_697_997),
        (6, 40_191_609),
        (7, 67_579_288),
        (8, 83_895_912),
        (9, 23_184_989),
        (.max, 27_790_413),
    ])
    func code_generatesSHA256EightDigitCodes(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: OTPRFCSecret.default, digits: 8, algorithm: .sha256)
        #expect(try sut.code(counter: counter) == value)
    }

    @Test(arguments: [
        (0, 125_165),
        (1, 342_147),
        (2, 730_102),
        (3, 778_726),
        (4, 937_510),
        (5, 848_329),
        (6, 266_680),
        (7, 588_359),
        (8, 39399),
        (9, 643_409),
        (.max, 381_515),
    ])
    func code_generatesSHA512SixDigitCodes(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: OTPRFCSecret.default, digits: 6, algorithm: .sha512)
        #expect(try sut.code(counter: counter) == value)
    }

    @Test(arguments: [
        (0, 4_125_165),
        (1, 9_342_147),
        (2, 1_730_102),
        (3, 3_778_726),
        (4, 1_937_510),
        (5, 6_848_329),
        (6, 6_266_680),
        (7, 2_588_359),
        (8, 5_039_399),
        (9, 3_643_409),
        (.max, 1_381_515),
    ])
    func code_generatesSHA512SevenDigitCodes(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: OTPRFCSecret.default, digits: 7, algorithm: .sha512)
        #expect(try sut.code(counter: counter) == value)
    }

    @Test(arguments: [
        (0, 4_125_165),
        (1, 69_342_147),
        (2, 71_730_102),
        (3, 73_778_726),
        (4, 81_937_510),
        (5, 16_848_329),
        (6, 36_266_680),
        (7, 22_588_359),
        (8, 45_039_399),
        (9, 33_643_409),
        (.max, 11_381_515),
    ])
    func code_generatesSHA512EightDigitCodes(counter: UInt64, value: BigUInt) throws {
        let sut = makeSUT(secret: OTPRFCSecret.default, digits: 8, algorithm: .sha512)
        #expect(try sut.code(counter: counter) == value)
    }

    // MARK: - Helpers

    private func makeSUT(
        secret: Data,
        digits: UInt16 = 6,
        algorithm: HOTPGenerator.Algorithm = .sha1,
    ) -> HOTPGenerator {
        HOTPGenerator(secret: secret, digits: digits, algorithm: algorithm)
    }

    private var zeroSecret: Data {
        Data(hex: "0")
    }
}
