import Foundation
import FoundationExtensions

public struct BackupPasswordExport {
    /// The version for this export, since it may be exported and imported
    /// by different versions of the vault app binary.
    var version: SemVer
    var key: Data
    var salt: Data
}

extension BackupPasswordExport: Codable {
    enum CodingKeys: String, CodingKey {
        case version = "VERSION"
        case key = "KEY"
        case salt = "SALT"
    }
}

// MARK: - Versions

extension BackupPasswordExport {
    static func createV1Export(key: Data, salt: Data) -> BackupPasswordExport {
        BackupPasswordExport(
            version: "1.0.0",
            key: key,
            salt: salt
        )
    }
}
