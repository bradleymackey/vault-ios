import Foundation

/// Retention period options for auto-backups.
public enum AutoBackupRetention: Int, CaseIterable, Codable, Sendable {
    case days7 = 7
    case days30 = 30
    case year1 = 365
    case forever = 0

    public var localizedTitle: String {
        switch self {
        case .days7: "7 days"
        case .days30: "30 days"
        case .year1: "1 year"
        case .forever: "Forever"
        }
    }

    /// Whether old backups should be cleaned up for this retention setting.
    public var shouldCleanup: Bool {
        self != .forever
    }
}

/// Configuration for automated backups.
public struct AutoBackupConfiguration: Codable, Equatable, Sendable {
    /// Whether auto-backup is enabled.
    public var isEnabled: Bool

    /// How many days of backup history to retain.
    public var retentionDays: AutoBackupRetention

    /// The ID of the active storage provider.
    public var providerID: String?

    /// Provider-specific configuration data, keyed by provider ID.
    public var providerConfigs: [String: Data]

    /// Hash of the last successful auto-backup payload.
    public var lastBackupHash: String?

    /// Date of the last successful auto-backup.
    public var lastBackupDate: Date?

    /// Creates a default configuration with auto-backup disabled.
    public init() {
        isEnabled = false
        retentionDays = .days30
        providerID = nil
        providerConfigs = [:]
        lastBackupHash = nil
        lastBackupDate = nil
    }

    public init(
        isEnabled: Bool,
        retentionDays: AutoBackupRetention,
        providerID: String?,
        providerConfigs: [String: Data],
        lastBackupHash: String?,
        lastBackupDate: Date?,
    ) {
        self.isEnabled = isEnabled
        self.retentionDays = retentionDays
        self.providerID = providerID
        self.providerConfigs = providerConfigs
        self.lastBackupHash = lastBackupHash
        self.lastBackupDate = lastBackupDate
    }
}
