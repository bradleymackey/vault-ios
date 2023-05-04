import Foundation
import OTPCore

public typealias OTPCodeStore = OTPCodeStoreReader & OTPCodeStoreWriter

public protocol OTPCodeStoreReader {
    /// Retrieve all stored codes from storage.
    func retrieve() async throws -> [StoredOTPCode]
}

public protocol OTPCodeStoreWriter {
    /// Insert an `OTPAuthCode` with a unique `id`.
    ///
    /// - Returns: The underlying ID of the entry in the store.
    @discardableResult
    func insert(code: OTPAuthCode) async throws -> UUID

    /// Update the code at the given ID.
    func update(id: UUID, code: OTPAuthCode) async throws

    /// Delete the code with the specific `id`.
    /// Has no effect if the code does not exist.
    func delete(id: UUID) async throws
}
