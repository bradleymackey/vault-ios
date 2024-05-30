import CryptoEngine
import CryptoSwift
import TestHelpers
import XCTest

final class ScryptKeyDeriverTests: XCTestCase {
    func test_key_doesNotThrowForValidParameters() async {
        let params = ScryptKeyDeriver.Parameters(
            outputLengthBytes: 32,
            costFactor: 1 << 4,
            blockSizeFactor: 2,
            parallelizationFactor: 1
        )
        let sut = ScryptKeyDeriver(parameters: params)

        await XCTAssertNoThrow(try sut.key(password: anyData(), salt: anyData()))
    }

    func test_key_throwsForInvalidParameters() async {
        let params = ScryptKeyDeriver.Parameters(
            outputLengthBytes: 32,
            costFactor: 16385,
            blockSizeFactor: 8,
            parallelizationFactor: 1
        )
        let sut = ScryptKeyDeriver(parameters: params)

        await XCTAssertThrowsError(try sut.key(password: anyData(), salt: anyData()))
    }

    func test_key_throwsIfMissingSalt() async {
        let sut = makeSUT(parameters: .fastForTesting)

        await XCTAssertThrowsError(try sut.key(password: anyData(), salt: Data()))
    }

    func test_key_generatesValidKeyWithSalt() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = makeSUT(parameters: .fastForTesting)

        let key = try sut.key(password: password, salt: salt)
        XCTAssertEqual(key, Data(hex: "14a1ba9b9236df39"))
    }

    func test_key_generatesValidKeyWithEmptyPassword() async throws {
        let password = Data()
        let salt = Data(hex: "ABCDEF")
        let sut = makeSUT(parameters: .fastForTesting)

        let key = try sut.key(password: password, salt: salt)
        XCTAssertEqual(key, Data(hex: "fa09cf2f564fb137"))
    }

    func test_key_generatesTheSameKeyMultipleTimes() async throws {
        let password = Data()
        let salt = Data(hex: "ABCDEF")
        let sut = makeSUT(parameters: .fastForTesting)

        let expected = Data(hex: "fa09cf2f564fb137")
        let keys = try [
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
        ]
        XCTAssertEqual(keys, [expected, expected, expected])
    }

    // MARK: - Helpers

    private func makeSUT(parameters: ScryptKeyDeriver.Parameters = .fastForTesting) -> ScryptKeyDeriver {
        ScryptKeyDeriver(parameters: parameters)
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
