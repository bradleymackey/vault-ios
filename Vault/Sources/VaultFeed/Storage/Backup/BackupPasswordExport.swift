import Foundation
import FoundationExtensions

struct BackupPasswordExport {
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
