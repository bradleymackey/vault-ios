import Foundation
import FoundationExtensions
import VaultBackup

/// Scanning the individual codes in a vault backup, recreate the EncryptedVault payload.
@Observable
public final class BackupImportScanningHandler: CodeScanningHandler {
    private var shardDecoder = DataShardDecoder()
    public init() {}

    public struct State {
        public var totalNumberOfShards: Int
        public var collectedShardIndexes: Set<Int>
        public var remainingShardIndexes: Set<Int>
    }

    public var shardState: State? {
        if let state = shardDecoder.state {
            State(
                totalNumberOfShards: state.total,
                collectedShardIndexes: state.collectedIndexes,
                remainingShardIndexes: state.remainingIndexes
            )
        } else {
            nil
        }
    }

    public func makeSimulatedHandler() -> some SimulatedCodeScanningHandler<EncryptedVault> {
        BackupImportScanningHandlerSimulated()
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

public final class BackupImportScanningHandlerSimulated: SimulatedCodeScanningHandler {
    public init() {}

    public func decodeSimulated() -> CodeScanningResult<EncryptedVault> {
        .endScanning(.dataRetrieved(makeExampleEncryptedVault()))
    }

    private func makeExampleEncryptedVault() -> EncryptedVault {
        EncryptedVault(
            data: Data(),
            authentication: Data(),
            encryptionIV: Data(),
            keygenSalt: Data(),
            keygenSignature: VaultKeyDeriver.Signature.testing.rawValue
        )
    }
}
