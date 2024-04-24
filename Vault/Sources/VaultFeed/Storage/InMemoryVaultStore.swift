import Foundation
import RegexBuilder

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

    public func retrieve(matching query: String) async throws -> [StoredVaultItem] {
        let pattern = Regex {
            ZeroOrMore { .any }
            query
            ZeroOrMore { .any }
        }.ignoresCase()
        return codes.filter { $0.matches(pattern: pattern) }
    }
}

extension StoredVaultItem {
    fileprivate func matches(pattern: Regex<Substring>) -> Bool {
        let fields: [String?] = [
            metadata.userDescription,
            item.otpCode?.data.accountName,
            item.otpCode?.data.issuer,
            item.secureNote?.title,
            item.secureNote?.contents,
        ]
        return fields.contains(where: { $0?.contains(pattern) == true })
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
