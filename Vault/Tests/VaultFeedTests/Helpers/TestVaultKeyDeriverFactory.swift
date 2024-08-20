import CryptoEngine
import Foundation
import FoundationExtensions
import VaultFeed

final class TestVaultKeyDeriverFactory: VaultKeyDeriverFactory {
    func makeVaultKeyDeriver() -> VaultKeyDeriver {
        VaultKeyDeriver.testing
    }
}
