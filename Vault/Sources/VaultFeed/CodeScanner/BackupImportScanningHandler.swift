import Foundation
import FoundationExtensions
import VaultBackup

/// Scanning the individual codes in a vault backup, recreate the EncryptedVault payload.
public final class BackupImportScanningHandler: CodeScanningHandler {
    private var shardDecoder = DataShardDecoder()
    public init() {}

    public func decode(data: String) throws -> CodeScanningResult<EncryptedVault> {
        let shardData = Data(data.utf8)
        try shardDecoder.add(shardData: shardData)
        if shardDecoder.isReadyToDecode {
            let encryptedVaultData = try shardDecoder.decodeData()
            let decodedEncryptedVault = try EncryptedVaultCoder().decode(vaultData: encryptedVaultData)
            return .completedScanning(decodedEncryptedVault)
        } else {
            return .continueScanning
        }
    }
}
