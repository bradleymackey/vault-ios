import CodeCryptoEngine
import CryptoSwift
import XCTest

final class ScryptKeyDeriverTests: XCTestCase {
    func test_init_doesNotThrowForValidParameters() {
        let params = ScryptKeyDeriver.Parameters(
            outputLengthBytes: 32,
            costFactor: 16384,
            blockSizeFactor: 8,
            parallelizationFactor: 1
        )
        XCTAssertNoThrow(try ScryptKeyDeriver(password: anyData(), salt: anyData(), parameters: params))
    }

    func test_init_doesNotThrowForAES256StrongVariant() {
        XCTAssertNoThrow(try ScryptKeyDeriver(password: anyData(), salt: anyData(), parameters: .aes256Strong))
    }

    func test_init_throwsForInvalidParameters() {
        let params = ScryptKeyDeriver.Parameters(
            outputLengthBytes: 32,
            costFactor: 16385,
            blockSizeFactor: 8,
            parallelizationFactor: 1
        )
        XCTAssertThrowsError(try ScryptKeyDeriver(password: anyData(), salt: anyData(), parameters: params))
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

    func test_key_generatesTheSameKeyMultipleTimes() async throws {
        let password = Data()
        let salt = Data(hex: "ABCDEF")

        let sut = try makeSUT(password: password, salt: salt, parameters: .fastForTesting)
        let expected = Data(hex: "fa09cf2f564fb137")
        let keys = [try await sut.key(), try await sut.key(), try await sut.key()]
        XCTAssertEqual(keys, [expected, expected, expected])
    }

    // MARK: - Helpers

    private func makeSUT(password: Data = anyData(), salt: Data = anyData(), parameters: ScryptKeyDeriver.Parameters = .fastForTesting) throws -> ScryptKeyDeriver {
        try ScryptKeyDeriver(password: password, salt: salt, parameters: parameters)
    }
}

extension ScryptKeyDeriver.Parameters {
    static var fastForTesting: Self {
        .init(
            outputLengthBytes: 8,
            costFactor: 16,
            blockSizeFactor: 2,
            parallelizationFactor: 1
        )
    }
}
