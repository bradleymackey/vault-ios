import Combine
import CryptoEngine
import Foundation
import FoundationExtensions
import VaultCore

/// Logs backup events so the user has visibility when the last one was performed.
///
/// @mockable
@MainActor
public protocol BackupEventLogger: Sendable {
    func lastBackupEvent() -> VaultBackupEvent?
    func exportedToPDF(date: Date, hash: Digest<VaultApplicationPayload>.SHA256)
    /// Publishes whenever an event is logged.
    var loggedEventPublisher: AnyPublisher<VaultBackupEvent, Never> { get }
}

// MARK: - Impl

public final class BackupEventLoggerImpl: BackupEventLogger {
    private let defaults: Defaults
    private let clock: any EpochClock
    private let backupEventKey = Key<VaultBackupEvent>(VaultIdentifiers.Backup.lastBackupEvent)
    private let loggedEventSubject = PassthroughSubject<VaultBackupEvent, Never>()

    public init(defaults: Defaults, clock: any EpochClock) {
        self.defaults = defaults
        self.clock = clock
    }

    public func lastBackupEvent() -> VaultBackupEvent? {
        defaults.get(for: backupEventKey)
    }

    public func exportedToPDF(date: Date, hash: Digest<VaultApplicationPayload>.SHA256) {
        let event = VaultBackupEvent(
            backupDate: clock.currentDate,
            eventDate: date,
            kind: .exportedToPDF,
            payloadHash: hash,
        )
        do {
            try defaults.set(event, for: backupEventKey)
            loggedEventSubject.send(event)
        } catch {
            // no event
        }
    }

    public var loggedEventPublisher: AnyPublisher<VaultBackupEvent, Never> {
        loggedEventSubject.eraseToAnyPublisher()
    }
}
