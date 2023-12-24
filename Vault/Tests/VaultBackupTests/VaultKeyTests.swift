import Foundation
import VaultBackup
import XCTest

final class VaultKeyTests: XCTestCase {
    func test_init_invalidKeyLengthThrows() {
        XCTAssertThrowsError(
            try VaultKey(
                key: Data(repeating: 0x31, count: 21),
                iv: Data(repeating: 0x31, count: 32)
            )
        )
    }

    func test_init_invalidIVLengthThrows() {
        XCTAssertThrowsError(
            try VaultKey(
                key: Data(repeating: 0x31, count: 32),
                iv: Data(repeating: 0x31, count: 21)
            )
        )
    }

    func test_init_validKeyLengthCreatesKey() throws {
        let sut = try VaultKey(key: Data(repeating: 0x31, count: 32), iv: Data(repeating: 0x31, count: 32))

        XCTAssertEqual(sut.iv.count, 32)
        XCTAssertEqual(sut.key.count, 32)
    }
}
