import Foundation
import XCTest

/// A key used to encrypt or decrypt a vault.
struct VaultKey {
    /// The key data for a vault.
    let key: Data
    /// Initialization vector.
    let iv: Data

    enum KeyError: Error {
        case invalidLength
    }

    enum IVError: Error {
        case invalidLength
    }

    init(key: Data, iv: Data) throws {
        guard key.count == 32 else { throw KeyError.invalidLength }
        guard iv.count == 32 else { throw IVError.invalidLength }
        self.key = key
        self.iv = iv
    }
}

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
