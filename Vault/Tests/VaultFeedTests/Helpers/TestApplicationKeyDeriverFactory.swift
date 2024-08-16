import CryptoEngine
import Foundation
import FoundationExtensions
import VaultFeed

final class TestApplicationKeyDeriverFactory: ApplicationKeyDeriverFactory {
    func makeApplicationKeyDeriver() -> ApplicationKeyDeriver<Bits256> {
        VaultAppKeyDerivers.testing
    }
}
