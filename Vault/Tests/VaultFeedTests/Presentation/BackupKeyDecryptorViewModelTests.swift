import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupKeyDecryptorViewModelTests: XCTestCase {
    @MainActor
    func test_init_setsInitialState() {
        let sut = makeSUT()

        XCTAssertEqual(sut.enteredPassword, "")
        XCTAssertEqual(sut.generated, .none)
    }

    @MainActor
    func test_generateKey_validPasswordGeneratesConsistentlyWithSalt() async throws {
        let sut = makeSUT(keyDeriver: .testing)
        sut.enteredPassword = "hello"
        let salt = Data(hex: "1234567890")

        await sut.generateKey(salt: salt)

        // Some consistent key for the given dummy data above.
        let expectedKey = Data(hex: "b79f4462edd8d360b23fd70c1b0e39b0849e89fc51fb176742df837452e18518")
        let expected = try DerivedEncryptionKey(key: .init(data: expectedKey), salt: salt, keyDervier: .testing)
        XCTAssertEqual(sut.generated.generatedKey, expected)
    }

    @MainActor
    func test_generateKey_emptyPasswordGeneratesError() async {
        let sut = makeSUT()
        sut.enteredPassword = ""

        await sut.generateKey(salt: Data())

        XCTAssertTrue(sut.generated.isError)
    }

    @MainActor
    func test_generateKey_keyDeriverErrorGeneratesError() async {
        let sut = makeSUT(keyDeriver: .failing)
        sut.enteredPassword = "hello"

        await sut.generateKey(salt: Data())

        XCTAssertTrue(sut.generated.isError)
    }
}

// MARK: - Helpers

extension BackupKeyDecryptorViewModelTests {
    @MainActor
    private func makeSUT(keyDeriver: VaultKeyDeriver = .testing) -> BackupKeyDecryptorViewModel {
        BackupKeyDecryptorViewModel(keyDeriver: keyDeriver)
    }
}
