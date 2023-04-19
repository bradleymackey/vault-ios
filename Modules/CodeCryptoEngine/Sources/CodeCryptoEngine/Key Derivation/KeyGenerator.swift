import Foundation

/// Can generate a key, usuaully a KDF.
public protocol KeyGenerator {
    func key() async throws -> Data
}
