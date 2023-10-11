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
}

extension InMemoryVaultStore: VaultStoreWriter {
    /// Thrown if a code cannot be found for a given operation.
    struct CodeNotFound: Error {}

    @discardableResult
    public func insert(code: StoredVaultItem.Write) async throws -> UUID {
        let code = StoredVaultItem(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: code.userDescription,
            code: code.code
        )
        codes.append(code)
        return code.id
    }

    public func update(id: UUID, code: StoredVaultItem.Write) async throws {
        guard let index = codes.firstIndex(where: { $0.id == id }) else {
            throw CodeNotFound()
        }
        let existingCode = codes[index]
        let newCode = StoredVaultItem(
            id: id,
            created: existingCode.created,
            updated: Date(),
            userDescription: code.userDescription,
            code: code.code
        )
        codes[index] = newCode
    }

    public func delete(id: UUID) async throws {
        codes.removeAll(where: { $0.id == id })
    }
}
