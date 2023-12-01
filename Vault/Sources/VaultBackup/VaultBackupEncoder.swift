import Foundation

/// Encodes an vault backup object to raw data for backup.
public final class VaultBackupEncoder {
    public init() {}

    public func encode(vaultBackup: VaultBackupPayload) throws -> Data {
        try makeEncoder().encode(vaultBackup)
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
