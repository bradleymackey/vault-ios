import Foundation
import VaultCore

public final class VaultBackupEncoder {
    private let clock: EpochClock

    public init(clock: EpochClock) {
        self.clock = clock
    }

    /// Encodes and encrypts a vault providing a payload.
    public func createExportPayload(items _: [VaultBackupItem], userDescription _: String) {
        // TODO: - return VaultExportPayload and implement
    }
}
