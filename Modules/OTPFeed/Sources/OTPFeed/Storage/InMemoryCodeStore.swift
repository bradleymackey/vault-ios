import Foundation

public final actor InMemoryCodeStore {
    private var codes: [StoredOTPCode]

    public init(codes: [StoredOTPCode] = []) {
        self.codes = codes
    }
}

extension InMemoryCodeStore: OTPCodeStoreReader {
    public func retrieve() async throws -> [StoredOTPCode] {
        codes
    }
}

extension InMemoryCodeStore: OTPCodeStoreWriter {
    /// Thrown if a code cannot be found for a given operation.
    struct CodeNotFound: Error {}

    @discardableResult
    public func insert(code: StoredOTPCode.Write) async throws -> UUID {
        let code = StoredOTPCode(
            id: UUID(),
            created: Date(),
            updated: Date(),
            userDescription: code.userDescription,
            code: code.code
        )
        codes.append(code)
        return code.id
    }

    public func update(id: UUID, code: StoredOTPCode.Write) async throws {
        guard let index = codes.firstIndex(where: { $0.id == id }) else {
            throw CodeNotFound()
        }
        let existingCode = codes[index]
        let newCode = StoredOTPCode(
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
