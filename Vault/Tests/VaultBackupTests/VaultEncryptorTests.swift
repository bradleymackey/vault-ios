import Foundation
import TestHelpers
import XCTest

final class VaultEncryptor {
    init() {}
    func encrypt(data: Data) throws -> Data {
        data
    }
}

final class VaultEncryptorTests: XCTestCase {
    func test_encrypt_emptyDataStaysEmpty() throws {
        let sut = VaultEncryptor()

        let result = try sut.encrypt(data: Data())

        XCTAssertEqual(result, Data())
    }
}
