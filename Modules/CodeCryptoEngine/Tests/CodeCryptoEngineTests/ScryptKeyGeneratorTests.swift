import CodeCryptoEngine
import CryptoSwift
import XCTest

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

    func test_key_generatesValidKeyWithSalt() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")

        let sut = try makeSUT(password: password, salt: salt, parameters: .fastForTesting)
        let key = try await sut.key()
        XCTAssertEqual(key, Data(hex: "14a1ba9b9236df39"))
    }

    func test_key_generatesValidKeyWithEmptyPassword() async throws {
        let password = Data()
        let salt = Data(hex: "ABCDEF")

        let sut = try makeSUT(password: password, salt: salt, parameters: .fastForTesting)
        let key = try await sut.key()
        XCTAssertEqual(key, Data(hex: "fa09cf2f564fb137"))
    }

    // MARK: - Helpers

    private func makeSUT(password: Data = anyData(), salt: Data = anyData(), parameters: ScryptKeyGenerator.Parameters = .fastForTesting) throws -> ScryptKeyGenerator {
        try ScryptKeyGenerator(password: password, salt: salt, parameters: parameters)
    }
}

func anyData() -> Data {
    Data(hex: "FF")
}

extension ScryptKeyGenerator.Parameters {
    static var fastForTesting: Self {
        .init(
            outputLengthBytes: 8,
            costFactor: 16,
            blockSizeFactor: 2,
            parallelizationFactor: 1
        )
    }
}
