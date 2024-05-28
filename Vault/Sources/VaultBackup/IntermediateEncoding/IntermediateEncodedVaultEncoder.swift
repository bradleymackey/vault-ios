import Foundation

/// Encodes an vault backup object to raw data for backup.
final class IntermediateEncodedVaultEncoder {
    init() {}

    func encode(vaultBackup: VaultBackupPayload) throws -> IntermediateEncodedVault {
        let data = try makeEncoder().encode(vaultBackup)
        return IntermediateEncodedVault(data: data)
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.dataEncodingStrategy = .base64
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.nonConformingFloatEncodingStrategy = .throw
        // predictable output format for testing
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
