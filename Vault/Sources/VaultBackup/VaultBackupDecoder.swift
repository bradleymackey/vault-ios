import Foundation

/// Decodes raw data to a vault backup payload object.
public final class VaultBackupDecoder {
    public init() {}

    public func decode(data: Data) throws -> VaultBackupPayload {
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
