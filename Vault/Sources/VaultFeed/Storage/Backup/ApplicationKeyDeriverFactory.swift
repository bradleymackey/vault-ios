import CryptoEngine
import Foundation

/// @mockable
public protocol ApplicationKeyDeriverFactory {
    func makeApplicationKeyDeriver() -> ApplicationKeyDeriver
}

public struct ApplicationKeyDeriverFactoryImpl: ApplicationKeyDeriverFactory {
    public init() {}
    public func makeApplicationKeyDeriver() -> ApplicationKeyDeriver {
        #if DEBUG
        // A fast key dervier that is relatively insecure, but runs in <5s in DEBUG on any reasonable hardware.
        return VaultAppKeyDerivers.V1.fast
        #else
        // This is very slow to run in DEBUG, due to lack of optimizations.
        return VaultAppKeyDerivers.V1.secure
        #endif
    }
}
