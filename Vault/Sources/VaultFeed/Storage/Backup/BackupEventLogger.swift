import CryptoEngine
import Foundation
import FoundationExtensions
import VaultCore

/// Logs backup events so the user has visibility when the last one was performed.
///
/// @mockable
public protocol BackupEventLogger {
    func exportedToPDF(date: Date, hash: Digest<VaultApplicationPayload>.SHA256)
}

// MARK: - Impl

public final class BackupEventLoggerImpl: BackupEventLogger {
    private let defaults: Defaults
    private let clock: EpochClock
    public init(defaults: Defaults, clock: EpochClock) {
        self.defaults = defaults
        self.clock = clock
    }

    public func exportedToPDF(date: Date, hash: Digest<VaultApplicationPayload>.SHA256) {
        let event = VaultBackupEvent(
            backupDate: clock.currentDate,
            eventDate: date,
            kind: .exportedToPDF,
            payloadHash: hash
        )
    }
}
