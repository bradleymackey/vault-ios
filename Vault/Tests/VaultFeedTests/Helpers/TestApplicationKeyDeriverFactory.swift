import CryptoEngine
import Foundation
import FoundationExtensions
import VaultFeed

final class TestApplicationKeyDeriverFactory: ApplicationKeyDeriverFactory {
    func makeApplicationKeyDeriver() -> ApplicationKeyDeriver {
        VaultAppKeyDerivers.testing
    }
}
