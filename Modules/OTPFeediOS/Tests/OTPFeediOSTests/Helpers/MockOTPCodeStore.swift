import Foundation
import OTPFeed
import OTPFeediOS

final class MockOTPCodeStore: OTPCodeStore {
    init() {}
    var codesToRetrieve = [StoredOTPCode]()
    var didRetrieveData: () -> Void = {}
    func retrieve() async throws -> [StoredOTPCode] {
        didRetrieveData()
        return codesToRetrieve
    }

    func delete(id _: UUID) async throws {
        // noop
    }

    func insert(code _: StoredOTPCode.Write) async throws -> UUID {
        UUID()
    }

    func update(id _: UUID, code _: StoredOTPCode.Write) async throws {
        // noop
    }
}
