import Foundation
import XCTest
@testable import FoundationExtensions

final class KeyDataTests: XCTestCase {
    func test_init_invalidKeyLengthThrows() {
        XCTAssertThrowsError(
            try KeyData<Bits256>(data: Data(repeating: 0x31, count: 21))
        )
    }

    func test_init_validKeyLengthCreatesKey() throws {
        let sut = try KeyData<Bits256>(data: Data(repeating: 0x31, count: 32))

        XCTAssertEqual(sut.data.count, 32)
    }

    func test_equatable_sameKeysEqual() throws {
        let sut1 = try KeyData<Bits256>(data: Data(repeating: 0x31, count: 32))
        let sut2 = try KeyData<Bits256>(data: Data(repeating: 0x31, count: 32))

        XCTAssertEqual(sut1, sut2)
    }

    func test_equatable_differentKeysDifferent() throws {
        let sut1 = try KeyData<Bits256>(data: Data(repeating: 0x31, count: 32))
        let sut2 = try KeyData<Bits256>(data: Data(repeating: 0x32, count: 32))

        XCTAssertNotEqual(sut1, sut2)
    }

    func test_random_createsRandomKey() throws {
        var seen = Set<KeyData<Bits256>>()
        for _ in 1 ... 100 {
            let key = KeyData<Bits256>.random()
            defer { seen.insert(key) }
            XCTAssertFalse(seen.contains(key))
        }
    }
}
