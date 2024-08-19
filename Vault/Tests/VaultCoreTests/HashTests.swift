import Foundation
import XCTest
@testable import VaultCore

final class HashTests: XCTestCase {
    func test_sha256_encodesToString() throws {
        let input = "8f434346a4c60c6d582a3d0a6c3c072b3d7a6b6a9b307d6b9b67e7b6c6e6f6b6"
        let result = Hash.SHA256(value: input)
        let encoded = try JSONEncoder().encode(result)
        let encodedStr = try XCTUnwrap(String(data: encoded, encoding: .utf8))

        XCTAssertEqual(encodedStr, "\"\(input)\"")
    }

    func test_sha256_decodesFromString() throws {
        let input = "8f434346a4c60c6d582a3d0a6c3c072b3d7a6b6a9b307d6b9b67e7b6c6e6f6b6"
        let encoded = Data("\"\(input)\"".utf8)
        let decoded = try JSONDecoder().decode(Hash.SHA256.self, from: encoded)

        XCTAssertEqual(decoded, Hash.SHA256(value: input))
    }
}
