import Foundation

public final actor InMemoryVaultStore {
    private var codes: [StoredVaultItem]

    public init(codes: [StoredVaultItem] = []) {
        self.codes = codes
    }
}

extension InMemoryVaultStore: VaultStoreReader {
    public func retrieve() async throws -> [StoredVaultItem] {
        codes
    }

    public func retrieve(matching _: String) async throws -> [StoredVaultItem] {
        // FIXME: actually implement this
        codes
    }
}

extension InMemoryVaultStore: VaultStoreWriter {
    /// Thrown if a code cannot be found for a given operation.
    struct CodeNotFound: Error {}

    @discardableResult
    public func insert(item: StoredVaultItem.Write) async throws -> UUID {
        let currentDate = Date()
        let metadata = StoredVaultItem.Metadata(
            id: UUID(),
            created: currentDate,
            updated: currentDate,
            userDescription: item.userDescription
        )
        let code = StoredVaultItem(
            metadata: metadata,
            item: item.item
        )
        codes.append(code)
        return code.id
    }

    public func update(id: UUID, item: StoredVaultItem.Write) async throws {
        guard let index = codes.firstIndex(where: { $0.id == id }) else {
            throw CodeNotFound()
        }
        let existingCode = codes[index]
        let metadata = StoredVaultItem.Metadata(
            id: id,
            created: existingCode.metadata.created,
            updated: Date(),
            userDescription: item.userDescription
        )
        let newCode = StoredVaultItem(
            metadata: metadata,
            item: item.item
        )
        codes[index] = newCode
    }

    public func delete(id: UUID) async throws {
        codes.removeAll(where: { $0.id == id })
    }
}
