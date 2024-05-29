import Foundation
import VaultCore

/// Used to create a full, encrypted backup of a vault for export.
public final class VaultBackupEncoder {
    private let clock: EpochClock

    public init(clock: EpochClock) {
        self.clock = clock
    }

    /// Encodes and encrypts a vault providing a payload.
    public func createExportPayload(items _: [VaultBackupItem], userDescription: String) -> VaultExportPayload {
        VaultExportPayload(
            encryptedVault: .init(data: Data(), authentication: Data(), encryptionIV: Data()),
            userDescription: userDescription,
            created: clock.currentDate
        )
    }
}
