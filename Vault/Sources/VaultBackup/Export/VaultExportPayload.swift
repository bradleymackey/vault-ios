import Foundation

/// Describes the full payload for export. For example to the `VaultDocumentExporter`.
///
/// - important: All sensitive data should already be included in the `EncryptedVault`.
/// Any other fields here should not contain senstive data.
public struct VaultExportPayload {
    var encryptedVault: EncryptedVault
    var userDescription: String
    var created: Date

    public init(encryptedVault: EncryptedVault, userDescription: String, created: Date) {
        self.encryptedVault = encryptedVault
        self.userDescription = userDescription
        self.created = created
    }
}
