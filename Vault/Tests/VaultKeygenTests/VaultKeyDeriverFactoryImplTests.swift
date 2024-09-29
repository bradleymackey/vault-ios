import Foundation
import TestHelpers
import Testing
@testable import VaultKeygen

struct VaultKeyDeriverFactoryImplTests {
    @Test
    func makeVaultKeyDeriver_debugGeneratesFast() {
        let sut = VaultKeyDeriverFactoryImpl()

        let result = sut.makeVaultKeyDeriver()

        #expect(result.signature == .fastV1, "We assume tests are run in DEBUG")
    }

    @Test(arguments: VaultKeyDeriver.Signature.allCases)
    func lookupVaultKeyDeriver_looksUpCorrect(signature: VaultKeyDeriver.Signature) {
        let sut = VaultKeyDeriverFactoryImpl()

        let result = sut.lookupVaultKeyDeriver(signature: signature)

        #expect(result.signature == signature)
    }
}
