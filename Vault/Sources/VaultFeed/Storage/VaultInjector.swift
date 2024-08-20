import Foundation

/// Object to retain and share non-observable dependencies across views.
///
/// Not all objects make sense as SwiftUI @Environment objects, but might still be needed in places.
/// This is a good place to store and subsequently inject them.
@Observable
public final class VaultInjector {
    public let backupEventLogger: any BackupEventLogger

    public init(backupEventLogger: any BackupEventLogger) {
        self.backupEventLogger = backupEventLogger
    }
}
