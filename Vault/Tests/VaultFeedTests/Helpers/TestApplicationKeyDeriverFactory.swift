import CryptoEngine
import Foundation
import VaultFeed

final class TestApplicationKeyDeriverFactory: ApplicationKeyDeriverFactory {
    func makeApplicationKeyDeriver() -> ApplicationKeyDeriver {
        VaultAppKeyDerivers.testing
    }
}
