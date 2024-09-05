import CryptoEngine
import Foundation
import FoundationExtensions

/// @mockable
public protocol VaultKeyDeriverFactory {
    func makeVaultKeyDeriver() -> VaultKeyDeriver
    func lookupVaultKeyDeriver(signature: VaultKeyDeriver.Signature) -> VaultKeyDeriver
}

public struct VaultKeyDeriverFactoryImpl: VaultKeyDeriverFactory {
    public init() {}
    public func makeVaultKeyDeriver() -> VaultKeyDeriver {
        #if DEBUG
        // A fast key dervier that is relatively insecure, but runs in <5s in DEBUG on any reasonable hardware.
        return VaultKeyDeriver.V1.fast
        #else
        // This is very slow to run in DEBUG, due to lack of optimizations.
        return VaultKeyDeriver.V1.secure
        #endif
    }

    public func lookupVaultKeyDeriver(signature: VaultKeyDeriver.Signature) -> VaultKeyDeriver {
        VaultKeyDeriver.lookup(signature: signature)
    }
}
