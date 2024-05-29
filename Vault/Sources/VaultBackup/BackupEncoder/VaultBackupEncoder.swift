import Foundation
import VaultCore

/// Used to create a full, encrypted backup of a vault for export.
public final class VaultBackupEncoder {
    private let clock: EpochClock
    private let key: VaultKey

    public init(clock: EpochClock, key: VaultKey) {
        self.clock = clock
        self.key = key
    }

    /// Encodes and encrypts a vault providing a payload.
    public func createExportPayload(
        items: [VaultBackupItem],
        userDescription: String
    ) throws -> VaultExportPayload {
        let currentDate = clock.currentDate
        let payload = VaultBackupPayload(
            version: .v1_0_0,
            created: currentDate,
            userDescription: userDescription,
            items: items,
            obfuscationPadding: Data()
        )
        let intermediateEncoding = try IntermediateEncodedVaultEncoder().encode(vaultBackup: payload)
        let encryptedVault = try VaultEncryptor(key: key).encrypt(encodedVault: intermediateEncoding)
        return VaultExportPayload(
            encryptedVault: encryptedVault,
            userDescription: userDescription,
            created: currentDate
        )
    }
}
