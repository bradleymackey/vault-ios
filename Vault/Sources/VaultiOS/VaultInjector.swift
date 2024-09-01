import Foundation
import VaultFeed

/// Object to retain and share non-observable dependencies across views.
///
/// Not all objects make sense as SwiftUI @Environment objects, but might still be needed in places.
/// This is a good place to store and subsequently inject them.
@Observable
public final class VaultInjector {
    public let clock: any EpochClock
    public let intervalTimer: any IntervalTimer
    public let backupEventLogger: any BackupEventLogger
    public let vaultKeyDeriverFactory: any VaultKeyDeriverFactory
    public let encryptedVaultDecoder: any EncryptedVaultDecoder
    public let defaults: Defaults
    public let fileManager: FileManager

    public init(
        clock: any EpochClock,
        intervalTimer: any IntervalTimer,
        backupEventLogger: any BackupEventLogger,
        vaultKeyDeriverFactory: any VaultKeyDeriverFactory,
        encryptedVaultDecoder: any EncryptedVaultDecoder,
        defaults: Defaults,
        fileManager: FileManager
    ) {
        self.clock = clock
        self.intervalTimer = intervalTimer
        self.backupEventLogger = backupEventLogger
        self.vaultKeyDeriverFactory = vaultKeyDeriverFactory
        self.encryptedVaultDecoder = encryptedVaultDecoder
        self.defaults = defaults
        self.fileManager = fileManager
    }
}
