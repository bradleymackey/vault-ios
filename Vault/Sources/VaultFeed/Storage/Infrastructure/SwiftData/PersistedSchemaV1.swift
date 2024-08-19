import Foundation
import SwiftData

enum PersistedSchemaV1: VersionedSchema, Sendable {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [PersistedVaultItem.self, PersistedOTPDetails.self, PersistedNoteDetails.self, PersistedVaultTag.self]
    }
}
