import Foundation
import OTPFeed
import OTPFeediOS

final class MockOTPCodeStore: VaultStore {
    init() {}
    var codesToRetrieve = [StoredVaultItem]()
    var didRetrieveData: () -> Void = {}
    func retrieve() async throws -> [StoredVaultItem] {
        didRetrieveData()
        return codesToRetrieve
    }

    func delete(id _: UUID) async throws {
        // noop
    }

    func insert(code _: StoredVaultItem.Write) async throws -> UUID {
        UUID()
    }

    func update(id _: UUID, code _: StoredVaultItem.Write) async throws {
        // noop
    }
}
