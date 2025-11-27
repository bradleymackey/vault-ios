import CryptoEngine
import Foundation
import Testing
import VaultCore

struct OTPAuthCodeTests {
    @Test(arguments: [
        (1, 4),
        (2, 24),
        (3, 224),
        (4, 5224),
        (5, 55224),
        (6, 755_224),
        (7, 4_755_224),
        (8, 84_755_224),
        (9, 284_755_224),
        (10, 1_284_755_224),
        (11, 1_284_755_224), // this is the actual value, so will be prepended with zeros before render
        (OTPAuthDigits(value: .max), 1_284_755_224),
    ] as [(OTPAuthDigits, BigUInt)])
    func hotpGenerator_expectedNumberOfDigits(digits: OTPAuthDigits, expected: BigUInt) throws {
        let generator = makeCode(digits: digits).data.hotpGenerator()
        #expect(try generator.code(counter: 0) == expected)
    }

    @Test(arguments: [
        (.sha1, 755_224),
        (.sha256, 875_740),
        (.sha512, 125_165),
    ] as [(OTPAuthAlgorithm, BigUInt)])
    func hotpGenerator_expectedValueForDifferentAlgorithm(algorithm: OTPAuthAlgorithm, expected: BigUInt) throws {
        let generator = makeCode(algorithm: algorithm).data.hotpGenerator()
        #expect(try generator.code(counter: 0) == expected)
    }
}

// MARK: - Helpers

extension OTPAuthCodeTests {
    private func makeCode(
        algorithm: OTPAuthAlgorithm = .default,
        digits: OTPAuthDigits = .default,
    ) -> OTPAuthCode {
        OTPAuthCode(
            type: .totp(),
            data: .init(secret: rfcSecret, algorithm: algorithm, digits: digits, accountName: "any"),
        )
    }

    var rfcSecret: OTPAuthSecret {
        let data = Data(byteString: "12345678901234567890")
        return .init(data: data, format: .base32)
    }
}
