import Foundation

/// Information about a backup file stored in a provider.
public struct BackupFileInfo: Equatable, Sendable {
    public let filename: String
    public let createdDate: Date
    public let size: Int64

    public init(filename: String, createdDate: Date, size: Int64) {
        self.filename = filename
        self.createdDate = createdDate
        self.size = size
    }
}

/// Protocol for any backup storage destination (iCloud Drive, Dropbox, local folder, etc.).
///
/// Each provider manages its own configuration persistence and folder access.
/// @mockable
public protocol BackupStorageProvider: Identifiable, Sendable {
    /// Unique identifier for this provider type.
    var id: String { get }

    /// Human-readable name for display in UI.
    var displayName: String { get }

    /// SF Symbol name for the provider icon.
    var iconSystemName: String { get }

    /// Whether the provider has been configured (e.g., folder selected).
    var isConfigured: Bool { get async }

    /// A short description of the current configuration (e.g., folder name).
    /// Returns nil if not configured.
    var configurationSummary: String? { get async }

    /// Check if the provider is currently available (e.g., iCloud signed in).
    var isAvailable: Bool { get async }

    /// Provider-specific configuration data for persistence.
    var configurationData: Data? { get async }

    /// Restore configuration from previously saved data.
    func restoreConfiguration(from data: Data) async throws

    /// Clear the provider's configuration.
    func clearConfiguration() async

    /// Configure the provider with a user-selected folder URL.
    func configure(with folderURL: URL) async throws

    /// Write backup data to the provider.
    /// - Parameters:
    ///   - data: The PDF backup data to write.
    ///   - filename: The filename to use (e.g., "vault-auto-backup-2025-01-11.pdf").
    func write(data: Data, filename: String) async throws

    /// List all backup files in the configured location.
    /// - Returns: Array of backup file information, sorted by date (newest first).
    func listBackups() async throws -> [BackupFileInfo]

    /// Delete a specific backup file.
    /// - Parameter filename: The filename to delete.
    func delete(filename: String) async throws
}
