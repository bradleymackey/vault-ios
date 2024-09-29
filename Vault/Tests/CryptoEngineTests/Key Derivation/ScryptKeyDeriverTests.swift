import CryptoEngine
import CryptoSwift
import Foundation
import FoundationExtensions
import TestHelpers
import Testing

struct ScryptKeyDeriverTests {
    @Test
    func key_doesNotThrowForValidParameters() async {
        let params = ScryptKeyDeriver<Bits64>.Parameters(
            costFactor: 1 << 4,
            blockSizeFactor: 2,
            parallelizationFactor: 1
        )
        let sut = ScryptKeyDeriver(parameters: params)

        #expect(throws: Never.self) {
            try sut.key(password: anyData(), salt: anyData())
        }
    }

    @Test
    func key_throwsForInvalidParameters() async {
        let params = ScryptKeyDeriver<Bits64>.Parameters(
            costFactor: 16385,
            blockSizeFactor: 8,
            parallelizationFactor: 1
        )
        let sut = ScryptKeyDeriver<Bits64>(parameters: params)

        #expect(throws: (any Error).self) {
            try sut.key(password: anyData(), salt: anyData())
        }
    }

    @Test
    func key_throwsIfMissingSalt() async {
        let sut = makeSUT(parameters: .fastForTesting)

        #expect(throws: (any Error).self) {
            try sut.key(password: anyData(), salt: Data())
        }
    }

    @Test
    func key_generatesValidKeyWithSalt() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = makeSUT(parameters: .fastForTesting)

        let key = try sut.key(password: password, salt: salt)
        #expect(key.data == Data(hex: "14a1ba9b9236df39"))
    }

    @Test
    func key_generatesValidKeyWithEmptyPassword() async throws {
        let password = Data()
        let salt = Data(hex: "ABCDEF")
        let sut = makeSUT(parameters: .fastForTesting)

        let key = try sut.key(password: password, salt: salt)
        #expect(key.data == Data(hex: "fa09cf2f564fb137"))
    }

    @Test
    func key_generatesTheSameKeyMultipleTimes() async throws {
        let password = Data()
        let salt = Data(hex: "ABCDEF")
        let sut = makeSUT(parameters: .fastForTesting)

        let expected = try KeyData<Bits64>(data: Data(hex: "fa09cf2f564fb137"))
        let keys = try [
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
        ]
        #expect(keys == [expected, expected, expected])
    }

    @Test
    func uniqueAlgorithmIdentifier_matchesParameters() {
        let sut = makeSUT(parameters: .init(
            costFactor: 998,
            blockSizeFactor: 432,
            parallelizationFactor: 555
        ))

        let expected = "SCRYPT<keyLength=8;costFactor=998;blockSizeFactor=432;parallelizationFactor=555>"
        #expect(sut.uniqueAlgorithmIdentifier == expected)
    }
}

// MARK: - Helpers

extension ScryptKeyDeriverTests {
    private func makeSUT(
        parameters: ScryptKeyDeriver<Bits64>
            .Parameters = .fastForTesting
    ) -> ScryptKeyDeriver<Bits64> {
        ScryptKeyDeriver(parameters: parameters)
    }
}

extension ScryptKeyDeriver.Parameters {
    static var fastForTesting: Self {
        .init(
            costFactor: 16,
            blockSizeFactor: 2,
            parallelizationFactor: 1
        )
    }
}
