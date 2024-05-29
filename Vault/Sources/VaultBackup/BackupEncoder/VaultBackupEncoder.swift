import Foundation
import VaultCore

/// Used to create a full, encrypted backup of a vault for export.
public final class VaultBackupEncoder {
    private let clock: EpochClock
    private let key: VaultKey
    private let paddingMode: PaddingMode

    public enum PaddingMode: Equatable {
        case none
        case fixed(bytes: Int)
        case random
    }

    public init(clock: EpochClock, key: VaultKey, paddingMode: PaddingMode = .random) {
        self.clock = clock
        self.key = key
        self.paddingMode = paddingMode
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
            obfuscationPadding: makePadding()
        )
        let intermediateEncoding = try IntermediateEncodedVaultEncoder().encode(vaultBackup: payload)
        let encryptedVault = try VaultEncryptor(key: key).encrypt(encodedVault: intermediateEncoding)
        return VaultExportPayload(
            encryptedVault: encryptedVault,
            userDescription: userDescription,
            created: currentDate
        )
    }

    private func makePadding() -> Data {
        switch paddingMode {
        case .none: Data()
        case let .fixed(bytes): Data.random(count: bytes)
        case .random: Data.random(count: Int.random(in: 30 ..< 30000))
        }
    }
}
