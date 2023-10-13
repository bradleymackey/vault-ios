import Foundation
import VaultCore

extension CoreDataVaultStore: VaultStoreReader {
    public func retrieve() async throws -> [StoredVaultItem] {
        try await asyncPerform { context in
            let results = try ManagedVaultItem.fetchAll(in: context)
            let decoder = ManagedVaultItemDecoder()
            return try results.map { managedCode in
                let vaultItem = try decoder.decode(item: managedCode)
                return StoredVaultItem(
                    id: managedCode.id,
                    created: managedCode.createdDate,
                    updated: managedCode.updatedDate,
                    userDescription: managedCode.userDescription,
                    item: vaultItem
                )
            }
        }
    }
}

extension CoreDataVaultStore: VaultStoreWriter {
    @discardableResult
    public func insert(item: StoredVaultItem.Write) async throws -> UUID {
        try await asyncPerform { context in
            do {
                let encoder = ManagedVaultItemEncoder(context: context)
                let encoded = encoder.encode(item: item)

                try context.save()
                return encoded.id
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    enum ManagedVaultItemError: Error {
        case entityNotFound
    }

    public func update(id: UUID, item: StoredVaultItem.Write) async throws {
        try await asyncPerform { context in
            do {
                guard let existingCode = try ManagedVaultItem.first(withID: id, in: context) else {
                    throw ManagedVaultItemError.entityNotFound
                }
                let encoder = ManagedVaultItemEncoder(context: context)
                _ = encoder.encode(item: item, into: existingCode)
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    public func delete(id: UUID) async throws {
        try await asyncPerform { context in
            let result = try ManagedVaultItem.first(withID: id, in: context)
            if let result {
                context.delete(result)
                try context.save()
            }
        }
    }
}
