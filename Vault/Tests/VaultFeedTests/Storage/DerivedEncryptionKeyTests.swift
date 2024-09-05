import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class DerivedEncryptionKeyTests: XCTestCase {
    func test_newVaultKeyWithRandomIV_usesSameKeyEachTime() throws {
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)

        var seenKeys = Set<KeyData<Bits256>>()
        for _ in 0 ..< 10 {
            let newKey = try key.newVaultKeyWithRandomIV()
            seenKeys.insert(newKey.key)
        }

        XCTAssertEqual(seenKeys.count, 1)
    }

    func test_newVaultKeyWithRandomIV_usesRandomIVEachTime() throws {
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)

        var seenIVs = Set<KeyData<Bits256>>()
        for _ in 0 ..< 10 {
            let newKey = try key.newVaultKeyWithRandomIV()
            seenIVs.insert(newKey.iv)
        }

        XCTAssertEqual(seenIVs.count, 10)
    }
}
