import CryptoEngine
import Foundation
import FoundationExtensions
import VaultCore

/// Used to create a full, encrypted backup of a vault for export.
public final class VaultBackupEncoder {
    private let clock: any EpochClock
    private let key: VaultKey
    private let keygenSalt: Data
    private let keygenSignature: String
    private let paddingMode: PaddingMode

    public enum PaddingMode: Equatable {
        case none
        case fixed(data: Data)
        case random
    }

    public init(
        clock: any EpochClock,
        key: VaultKey,
        keygenSalt: Data,
        keygenSignature: String,
        paddingMode: PaddingMode = .random
    ) {
        self.clock = clock
        self.key = key
        self.keygenSalt = keygenSalt
        self.keygenSignature = keygenSignature
        self.paddingMode = paddingMode
    }

    /// Encodes and encrypts a vault providing a payload.
    public func createExportPayload(
        items: [VaultBackupItem],
        tags: [VaultBackupTag],
        userDescription: String
    ) throws -> EncryptedVault {
        let payload = VaultBackupPayload(
            version: "1.0.0",
            created: clock.currentDate,
            userDescription: userDescription,
            tags: tags,
            items: items,
            obfuscationPadding: makePadding(itemsCount: items.count)
        )
        let intermediateEncoding = try IntermediateEncodedVaultEncoder().encode(vaultBackup: payload)
        let encryptor = VaultEncryptor(key: key, keygenSalt: keygenSalt, keygenSignature: keygenSignature)
        return try encryptor.encrypt(encodedVault: intermediateEncoding)
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
