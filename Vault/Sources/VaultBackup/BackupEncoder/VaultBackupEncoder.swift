import Foundation
import VaultCore

/// Used to create a full, encrypted backup of a vault for export.
public final class VaultBackupEncoder {
    private let clock: EpochClock
    private let key: VaultKey
    private let keySalt: Data
    private let paddingMode: PaddingMode

    public enum PaddingMode: Equatable {
        case none
        case fixed(data: Data)
        case random
    }

    public init(clock: EpochClock, key: VaultKey, keySalt: Data, paddingMode: PaddingMode = .random) {
        self.clock = clock
        self.key = key
        self.keySalt = keySalt
        self.paddingMode = paddingMode
    }

    /// Encodes and encrypts a vault providing a payload.
    public func createExportPayload(items: [VaultBackupItem], userDescription: String) throws -> EncryptedVault {
        let payload = VaultBackupPayload(
            version: .v1_0_0,
            created: clock.currentDate,
            userDescription: userDescription,
            items: items,
            obfuscationPadding: makePadding(itemsCount: items.count)
        )
        let intermediateEncoding = try IntermediateEncodedVaultEncoder().encode(vaultBackup: payload)
        return try VaultEncryptor(key: key, keySalt: keySalt).encrypt(encodedVault: intermediateEncoding)
    }

    private func makePadding(itemsCount: Int) -> Data {
        switch paddingMode {
        case .none: Data()
        case let .fixed(data): data
        case .random: Data.random(count: randomBytesToGenerate(itemsCount: itemsCount))
        }
    }

    private func randomBytesToGenerate(itemsCount: Int) -> Int {
        if itemsCount == 0 {
            Int.random(in: 400 ..< 2700)
        } else if itemsCount < 10 {
            Int.random(in: 300 ..< 3300)
        } else if itemsCount < 40 {
            Int.random(in: 600 ..< 4500)
        } else {
            Int.random(in: 200 ..< 6000)
        }
    }
}
