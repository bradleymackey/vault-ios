import Foundation
import TestHelpers
import Testing
@testable import VaultKeygen

struct VaultKeyDeriverFactoryImplTests {
    @Test
    func makeVaultBackupKeyDeriver_debugGeneratesFast() {
        let sut = VaultKeyDeriverFactoryImpl()

        let result = sut.makeVaultBackupKeyDeriver()

        #expect(result.signature == .backupFastV1, "We assume tests are run in DEBUG")
    }

    @Test
    func makeVaultItemKeyDeriver_debugGeneratesFast() {
        let sut = VaultKeyDeriverFactoryImpl()

        let result = sut.makeVaultItemKeyDeriver()

        #expect(result.signature == .itemFastV1, "We assume tests are run in DEBUG")
    }

    @Test(arguments: VaultKeyDeriver.Signature.allCases)
    func lookupVaultKeyDeriver_looksUpCorrect(signature: VaultKeyDeriver.Signature) {
        let sut = VaultKeyDeriverFactoryImpl()

        let result = sut.lookupVaultKeyDeriver(signature: signature)

        #expect(result.signature == signature)
    }
}
