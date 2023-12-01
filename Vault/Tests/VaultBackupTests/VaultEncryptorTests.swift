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
        let sut = makeSUT()

        let result = try sut.encrypt(data: Data())

        XCTAssertEqual(result, Data())
    }
}

// MARK: - Helpers

extension VaultEncryptorTests {
    private func makeSUT() -> VaultEncryptor {
        let sut = VaultEncryptor()
        trackForMemoryLeaks(sut)
        return sut
    }
}
