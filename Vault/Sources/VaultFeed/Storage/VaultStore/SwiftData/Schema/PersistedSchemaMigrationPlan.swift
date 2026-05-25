import Foundation
import SwiftData

enum PersistedSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PersistedSchemaV1.self, PersistedSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [v1ToV2]
    }

    /// V1 → V2 swaps plaintext `killphrase` for the salted-HMAC pair
    /// `(killphraseSalt, killphraseDigest)`.
    ///
    /// The HMAC key is derived from the user's vault key, which is not
    /// available at migration time (the user has not yet unlocked). So the
    /// migration runs in two phases:
    ///
    /// 1. **`willMigrate`** — snapshots every `(itemID, plaintext)` pair
    ///    where `killphrase` was non-`nil` into a sibling file with file
    ///    protection. The plaintext field is then dropped by SwiftData as
    ///    part of the schema swap to V2.
    /// 2. **`didMigrate`** — no-op here: the rehash is performed later by
    ///    `KillphraseRehashService.run(digester:)` once the user unlocks
    ///    the vault for the first time after upgrading.
    ///
    /// The window between Phase 1 and Phase 2 is the only time plaintext
    /// killphrases live outside the SwiftData store. The pending file is
    /// securely overwritten and deleted by the rehash service.
    static let v1ToV2 = MigrationStage.custom(
        fromVersion: PersistedSchemaV1.self,
        toVersion: PersistedSchemaV2.self,
        willMigrate: { context in
            let descriptor = FetchDescriptor<PersistedSchemaV1.PersistedVaultItem>()
            let items = try context.fetch(descriptor)
            let entries: [PendingKillphraseRehashStore.Entry] = items.compactMap { item in
                guard let phrase = item.killphrase, phrase.isEmpty == false else { return nil }
                return .init(itemID: item.id, phrase: phrase)
            }
            guard entries.isEmpty == false else { return }

            let storeURL = pendingStoreURL(for: context)
            let pending = PendingKillphraseRehashStore(fileURL: storeURL)
            try pending.write(entries)
        },
        didMigrate: nil,
    )

    /// Best-effort lookup of the directory containing the SwiftData store,
    /// so the pending-rehash file can live alongside it.
    private static func pendingStoreURL(for context: ModelContext) -> URL {
        let directory: URL = if let configURL = context.container.configurations.first?.url {
            configURL.deletingLastPathComponent()
        } else {
            URL.applicationSupportDirectory
        }
        return PendingKillphraseRehashStore.defaultURL(storeDirectory: directory)
    }
}
