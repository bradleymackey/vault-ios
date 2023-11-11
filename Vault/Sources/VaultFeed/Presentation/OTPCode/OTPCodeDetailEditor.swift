import Foundation
import VaultCore

public protocol OTPCodeDetailEditor {
    func update(id: UUID, item: OTPAuthCode, edits: OTPCodeDetailEdits) async throws
    func deleteCode(id: UUID) async throws
}
