import CodeCryptoEngine
import CryptoSwift
import XCTest

final class TOTPGeneratorTests: XCTestCase {
    func test_verify_matchesExpected() throws {
        let hotp = HOTPGenerator(secret: anyData())
        let sut = TOTPGenerator(generator: hotp)

        let expected = try sut.code(epochSeconds: 10)
        try XCTAssertTrue(sut.verify(epochSeconds: 10, value: expected))
    }

    func test_verify_doesNotMatchExpected() throws {
        let hotp = HOTPGenerator(secret: anyData())
        let sut = TOTPGenerator(generator: hotp)

        let expected = try sut.code(epochSeconds: 10)
        try XCTAssertFalse(sut.verify(epochSeconds: 10, value: expected + 1))
    }

    func test_code_rfcSHA1Example() throws {
        let secret = Data(byteString: "12345678901234567890")
        let hotp = HOTPGenerator(secret: secret, digits: .eight, algorithm: .sha1)
        let sut = TOTPGenerator(generator: hotp, timeInterval: 30)

        try XCTAssertEqual(sut.code(epochSeconds: 59), 94_287_082)
        try XCTAssertEqual(sut.code(epochSeconds: 1_111_111_109), 07_081_804)
        try XCTAssertEqual(sut.code(epochSeconds: 1_111_111_111), 14_050_471)
        try XCTAssertEqual(sut.code(epochSeconds: 1_234_567_890), 89_005_924)
        try XCTAssertEqual(sut.code(epochSeconds: 2_000_000_000), 69_279_037)
        try XCTAssertEqual(sut.code(epochSeconds: 20_000_000_000), 65_353_130)
    }

    func test_code_rfcSHA256Example() {
        let secret = Data(byteString: "12345678901234567890123456789012")
        let hotp = HOTPGenerator(secret: secret, digits: .eight, algorithm: .sha256)
        let sut = TOTPGenerator(generator: hotp, timeInterval: 30)

        try XCTAssertEqual(sut.code(epochSeconds: 59), 46_119_246)
        try XCTAssertEqual(sut.code(epochSeconds: 1_111_111_109), 68_084_774)
        try XCTAssertEqual(sut.code(epochSeconds: 1_111_111_111), 67_062_674)
        try XCTAssertEqual(sut.code(epochSeconds: 1_234_567_890), 91_819_424)
        try XCTAssertEqual(sut.code(epochSeconds: 2_000_000_000), 90_698_825)
        try XCTAssertEqual(sut.code(epochSeconds: 20_000_000_000), 77_737_706)
    }

    func test_code_rfcSHA512Example() {
        let secret = Data(byteString: "1234567890123456789012345678901234567890123456789012345678901234")
        let hotp = HOTPGenerator(secret: secret, digits: .eight, algorithm: .sha512)
        let sut = TOTPGenerator(generator: hotp, timeInterval: 30)

        try XCTAssertEqual(sut.code(epochSeconds: 59), 90_693_936)
        try XCTAssertEqual(sut.code(epochSeconds: 1_111_111_109), 25_091_201)
        try XCTAssertEqual(sut.code(epochSeconds: 1_111_111_111), 99_943_326)
        try XCTAssertEqual(sut.code(epochSeconds: 1_234_567_890), 93_441_116)
        try XCTAssertEqual(sut.code(epochSeconds: 2_000_000_000), 38_618_901)
        try XCTAssertEqual(sut.code(epochSeconds: 20_000_000_000), 47_863_826)
    }
}
