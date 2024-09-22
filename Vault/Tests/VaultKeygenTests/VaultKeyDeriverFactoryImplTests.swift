import Foundation
import TestHelpers
import XCTest
@testable import VaultKeygen

final class VaultKeyDeriverFactoryImplTests: XCTestCase {
    // Assumption: tests are run in DEBUG configuration
    func test_makeVaultKeyDeriver_debugGeneratesFast() {
        let sut = VaultKeyDeriverFactoryImpl()

        let result = sut.makeVaultKeyDeriver()

        XCTAssertEqual(result.signature, .fastV1)
    }

    func test_lookupVaultKeyDeriver_looksUpCorrect() {
        let signatures = VaultKeyDeriver.Signature.allCases
        for signature in signatures {
            let sut = VaultKeyDeriverFactoryImpl()

            let result = sut.lookupVaultKeyDeriver(signature: signature)

            XCTAssertEqual(result.signature, signature)
        }
    }
}
