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

/// Always uses and looks up the testing deriver, to ensure that tests run fast.
public struct VaultKeyDeriverFactoryTesting: VaultKeyDeriverFactory {
    public init() {}
    public func makeVaultKeyDeriver() -> VaultKeyDeriver { .testing }
    public func lookupVaultKeyDeriver(signature _: VaultKeyDeriver.Signature) -> VaultKeyDeriver { .testing }
}

extension VaultKeyDeriverFactory where Self == VaultKeyDeriverFactoryTesting {
    public static var testing: Self { VaultKeyDeriverFactoryTesting() }
}

/// Always uses the key deriver that generates a key generation error.
public struct VaultKeyDeriverFactoryFailing: VaultKeyDeriverFactory {
    public init() {}
    public func makeVaultKeyDeriver() -> VaultKeyDeriver { .failing }
    public func lookupVaultKeyDeriver(signature _: VaultKeyDeriver.Signature) -> VaultKeyDeriver { .failing }
}

extension VaultKeyDeriverFactory where Self == VaultKeyDeriverFactoryFailing {
    public static var failing: Self { VaultKeyDeriverFactoryFailing() }
}
