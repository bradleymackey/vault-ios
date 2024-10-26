import Foundation
import FoundationExtensions
import VaultBackup

/// Scanning the individual codes in a vault backup, recreate the EncryptedVault payload.
@Observable
public final class BackupImportScanningHandler: CodeScanningHandler {
    private var shardDecoder = DataShardDecoder()
    public init() {}

    public var totalNumberOfShards: Int? {
        shardDecoder.state?.total
    }

    public var remainingShardIndexes: Set<Int>? {
        shardDecoder.state?.remainingIndexes
    }

    public var collectedShardIndexes: Set<Int>? {
        shardDecoder.state?.collectedIndexes
    }

    public var remainingShards: Int? {
        remainingShardIndexes?.count
    }

    public func decode(data: String) -> CodeScanningResult<EncryptedVault> {
        let shardData = Data(data.utf8)
        do {
            try shardDecoder.add(shardData: shardData)
            if !shardDecoder.isReadyToDecode { return .continueScanning(.success) }
        } catch let error as DataShardDecoder.AddShardError where error.canIgnoreError {
            return .continueScanning(.ignore)
        } catch {
            return .continueScanning(.invalidCode)
        }

        do {
            let encryptedVault = try decodeEncryptedVault()
            return .endScanning(.dataRetrieved(encryptedVault))
        } catch {
            // We cannot recover if this fails because the state is tainted and we
            // have no idea what caused it.
            return .endScanning(.unrecoverableError)
        }
    }

    private func decodeEncryptedVault() throws -> EncryptedVault {
        let encryptedVaultData = try shardDecoder.decodeData()
        let decodedEncryptedVault = try EncryptedVaultCoder().decode(vaultData: encryptedVaultData)
        return decodedEncryptedVault
    }
}
