import CodeCryptoEngine
import CryptoSwift
import XCTest

/// A key generator, generating a 256-bit key using Scrypt.
struct ScryptKeyGenerator {
    private let engine: Scrypt

    struct Parameters {
        /// **dkLen**
        ///
        /// Desired key length in bytes (Intended output length in octets of the derived key; a positive integer satisfying dkLen ≤ (232− 1) * hLen.)
        var outputLengthBytes: Int
        /// **N**
        ///
        /// CPU/memory cost parameter – Must be a power of 2 (e.g. 1024)
        var costFactor: Int
        /// **r**
        ///
        /// blocksize parameter, which fine-tunes sequential memory read size and performance. (8 is commonly used)
        var blockSizeFactor: Int
        ///
        ///
        /// Parallelization parameter. (1 .. 232-1 * hLen/MFlen)
        var parallelizationFactor: Int
    }

    init(password: Data, salt: Data, parameters: Parameters) throws {
        engine = try Scrypt(
            password: password.bytes,
            salt: salt.bytes,
            dkLen: parameters.outputLengthBytes,
            N: parameters.costFactor,
            r: parameters.blockSizeFactor,
            p: parameters.parallelizationFactor
        )
    }

    func key() throws -> Data {
        try Data(engine.calculate())
    }
}

extension ScryptKeyGenerator.Parameters {
    static var aes256Strong: Self {
        .init(
            outputLengthBytes: 32,
            costFactor: 16384,
            blockSizeFactor: 8,
            parallelizationFactor: 1
        )
    }

    static var fastForTesting: Self {
        .init(
            outputLengthBytes: 8,
            costFactor: 16,
            blockSizeFactor: 2,
            parallelizationFactor: 1
        )
    }
}

final class KeyGeneratorV1Tests: XCTestCase {
    func test_init_doesNotThrowForValidParameters() {
        let params = ScryptKeyGenerator.Parameters(
            outputLengthBytes: 32,
            costFactor: 16384,
            blockSizeFactor: 8,
            parallelizationFactor: 1
        )
        XCTAssertNoThrow(try ScryptKeyGenerator(password: anyData(), salt: anyData(), parameters: params))
    }

    func test_init_doesNotThrowForAES256StrongVariant() {
        XCTAssertNoThrow(try ScryptKeyGenerator(password: anyData(), salt: anyData(), parameters: .aes256Strong))
    }

    func test_init_throwsForInvalidParameters() {
        let params = ScryptKeyGenerator.Parameters(
            outputLengthBytes: 32,
            costFactor: 16385,
            blockSizeFactor: 8,
            parallelizationFactor: 1
        )
        XCTAssertThrowsError(try ScryptKeyGenerator(password: anyData(), salt: anyData(), parameters: params))
    }

    func test_init_throwsIfMissingSalt() {
        XCTAssertThrowsError(try makeSUT(password: anyData(), salt: Data(), parameters: .fastForTesting))
    }

    func test_key_generatesValidKeyWithSalt() throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")

        let sut = try makeSUT(password: password, salt: salt, parameters: .fastForTesting)
        try XCTAssertEqual(sut.key(), Data(hex: "14a1ba9b9236df39"))
    }

    func test_key_generatesValidKeyWithEmptyPassword() throws {
        let password = Data()
        let salt = Data(hex: "ABCDEF")

        let sut = try makeSUT(password: password, salt: salt, parameters: .fastForTesting)
        try XCTAssertEqual(sut.key(), Data(hex: "fa09cf2f564fb137"))
    }

    // MARK: - Helpers

    private func makeSUT(password: Data = anyData(), salt: Data = anyData(), parameters: ScryptKeyGenerator.Parameters = .fastForTesting) throws -> ScryptKeyGenerator {
        try ScryptKeyGenerator(password: password, salt: salt, parameters: parameters)
    }
}

func anyData() -> Data {
    Data(hex: "FF")
}
