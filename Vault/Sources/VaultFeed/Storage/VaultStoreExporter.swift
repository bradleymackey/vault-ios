import Foundation

/// @mockable
public protocol VaultStoreExporter: Sendable {
    func exportVault() async throws -> VaultApplicationPayload
}
