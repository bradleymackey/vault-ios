import Foundation

/// Encodes an vault backup object to raw data for backup.
final class VaultBackupEncoder {
    init() {}

    func encode(vaultBackup: VaultBackupPayload) throws -> EncodedVault {
        let data = try makeEncoder().encode(vaultBackup)
        return EncodedVault(data: data)
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
