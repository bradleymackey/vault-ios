import Foundation
import OTPCore

extension CoreDataCodeStore: OTPCodeStoreReader {
    public func retrieve() async throws -> [StoredOTPCode] {
        try await asyncPerform { context in
            let results = try ManagedOTPCode.fetchAll(in: context)
            let decoder = ManagedOTPCodeDecoder()
            return try results.map { managedCode in
                let code = try decoder.decode(code: managedCode)
                return StoredOTPCode(id: managedCode.id, code: code)
            }
        }
    }
}

extension CoreDataCodeStore: OTPCodeStoreWriter {
    @discardableResult
    public func insert(code: OTPAuthCode) async throws -> UUID {
        try await asyncPerform { context in
            do {
                let encoder = ManagedOTPCodeEncoder(context: context)
                let encoded = encoder.encode(code: code)

                try context.save()
                return encoded.id
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    enum ManagedOTPCodeError: Error {
        case entityNotFound
    }

    public func update(id: UUID, code: OTPAuthCode) async throws {
        try await asyncPerform { context in
            do {
                guard let existingCode = try ManagedOTPCode.first(withID: id, in: context) else {
                    throw ManagedOTPCodeError.entityNotFound
                }
                let encoder = ManagedOTPCodeEncoder(context: context)
                _ = encoder.encode(code: code, into: existingCode)
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    public func delete(id: UUID) async throws {
        try await asyncPerform { context in
            let result = try ManagedOTPCode.first(withID: id, in: context)
            if let result {
                context.delete(result)
                try context.save()
            }
        }
    }
}
