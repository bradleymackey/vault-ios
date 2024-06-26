import Foundation

/// @mockable
public protocol VaultStoreExporter: Sendable {
    func exportVault(userDescription: String) async throws -> VaultApplicationPayload
}
