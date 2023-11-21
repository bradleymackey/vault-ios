import Foundation
import XCTest
@testable import VaultBackup

final class VaultBackupVersionTests: XCTestCase {
    func test_allCases_onlyHasV1() {
        XCTAssertEqual(VaultBackupVersion.allCases, [.v1])
    }

    func test_codable_usesPointVersionNumbers() throws {
        let encoder = JSONEncoder()
        let sut = try VaultBackupVersion.allCases
            .map { try encoder.encode($0) }
            .map { try XCTUnwrap(String(data: $0, encoding: .utf8)) }

        XCTAssertEqual(sut, [#""1.0""#])
    }
}
