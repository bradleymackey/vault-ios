import Foundation
import XCTest
@testable import VaultCore

final class HashTests: XCTestCase {
    func test_sha256_encodesToStringBase64() throws {
        let input = Data(hex: "8f434346a4c60c6d582a3d0a6c3c072b3d7a6b6a9b307d6b9b67e7b6c6e6f6b6")
        let result = Hash<Any>.SHA256(value: input)
        let encoded = try JSONEncoder().encode(result)
        let encodedStr = try XCTUnwrap(String(data: encoded, encoding: .utf8))

        XCTAssertEqual(encodedStr, "\"\(input.base64EncodedString())\"")
    }

    func test_sha256_decodesFromStringBase64() throws {
        let input = Data(hex: "8f434346a4c60c6d582a3d0a6c3c072b3d7a6b6a9b307d6b9b67e7b6c6e6f6b6")
        let json = Data("\"\(input.base64EncodedString())\"".utf8)
        let decoded = try JSONDecoder().decode(Hash<Any>.SHA256.self, from: json)

        XCTAssertEqual(decoded, Hash<Any>.SHA256(value: input))
    }
}
