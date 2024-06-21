import Foundation
import VaultCore

/// @mockable
@MainActor
public protocol OTPCodeDetailEditor {
    func createCode(initialEdits: OTPCodeDetailEdits) async throws
    func updateCode(id: UUID, item: OTPAuthCode, edits: OTPCodeDetailEdits) async throws
    func deleteCode(id: UUID) async throws
}
