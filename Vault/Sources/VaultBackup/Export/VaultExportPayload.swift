import Foundation

/// Describes the payload for export. For example to the `VaultDocumentExporter`.
///
/// - important: All sensitive data should already be included in the `EncryptedVault`.
/// Any other fields here should not contain senstive data.
///
/// This payload is export-only, as only the `encryptedVault` is required to be
/// decrypted, parsed and imported.
/// The other fields don't need importing.
public struct VaultExportPayload {
    var encryptedVault: EncryptedVault
    var userDescription: String
    var created: Date
}
