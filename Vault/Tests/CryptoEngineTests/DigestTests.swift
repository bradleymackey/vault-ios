import Foundation
import Testing
@testable import CryptoEngine

struct DigestTests {
    @Test
    func sha256_encodesToStringBase64() throws {
        let input = Data(hex: "8f434346a4c60c6d582a3d0a6c3c072b3d7a6b6a9b307d6b9b67e7b6c6e6f6b6")
        let result = Digest<Any>.SHA256(value: input)
        let encoded = try JSONEncoder().encode(result)
        let encodedStr = try #require(String(data: encoded, encoding: .utf8))

        #expect(encodedStr == "\"\(input.base64EncodedString())\"")
    }

    @Test
    func sha256_decodesFromStringBase64() throws {
        let input = Data(hex: "8f434346a4c60c6d582a3d0a6c3c072b3d7a6b6a9b307d6b9b67e7b6c6e6f6b6")
        let json = Data("\"\(input.base64EncodedString())\"".utf8)
        let decoded = try JSONDecoder().decode(Digest<Any>.SHA256.self, from: json)

        #expect(decoded == Digest<Any>.SHA256(value: input))
    }
}
