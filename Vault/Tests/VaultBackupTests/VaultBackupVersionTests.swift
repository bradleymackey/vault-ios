import Foundation
import VaultBackup
import XCTest

final class VaultBackupVersionTests: XCTestCase {
    func test_allCases_onlyHasV1() {
        XCTAssertEqual(VaultBackupVersion.allCases, [.v1_0_0])
    }

    func test_codable_usesSemanticVersionNumbers() throws {
        let encoder = JSONEncoder()
        let sut = try VaultBackupVersion.allCases
            .map { try encoder.encode($0) }
            .map { try XCTUnwrap(String(data: $0, encoding: .utf8)) }

        XCTAssertEqual(sut, [#""1.0.0""#])
    }
}
