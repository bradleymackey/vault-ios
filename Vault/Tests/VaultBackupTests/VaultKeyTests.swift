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

    func test_newKeyWithRandomIV_throwsForInvalidKeyLength() {
        XCTAssertThrowsError(try VaultKey.newKeyWithRandomIV(key: Data.random(count: 1)))
    }

    func test_newKeyWithRandomIV_makesValidKeyAndIVLength() throws {
        for _ in 1 ... 100 {
            let data = Data.random(count: 32)
            let key = try VaultKey.newKeyWithRandomIV(key: data)

            XCTAssertEqual(key.key, data)
            XCTAssertEqual(key.iv.count, 32)
        }
    }
}
