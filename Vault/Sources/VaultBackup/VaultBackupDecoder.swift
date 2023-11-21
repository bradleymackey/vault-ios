import Foundation

/// Decodes raw data to a vault backup payload object.
final class VaultBackupDecoder {
    init() {}

    func decode(data: Data) throws -> VaultBackupPayload {
        try makeDecoder().decode(VaultBackupPayload.self, from: data)
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.dataDecodingStrategy = .base64
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.nonConformingFloatDecodingStrategy = .throw
        return decoder
    }
}
