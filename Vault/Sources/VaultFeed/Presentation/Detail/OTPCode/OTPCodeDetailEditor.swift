import Foundation
import FoundationExtensions
import VaultCore

/// @mockable
@MainActor
public protocol OTPCodeDetailEditor {
    func createCode(initialEdits: OTPCodeDetailEdits) async throws
    func updateCode(id: Identifier<VaultItem>, item: OTPAuthCode, edits: OTPCodeDetailEdits) async throws
    func deleteCode(id: Identifier<VaultItem>) async throws
}
