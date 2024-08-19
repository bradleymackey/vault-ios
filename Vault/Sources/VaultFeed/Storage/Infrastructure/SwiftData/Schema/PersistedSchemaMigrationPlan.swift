import Foundation
import SwiftData

enum PersistedSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PersistedSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // There are no migrations yet, as we only have a V1 schema.
        []
    }
}
