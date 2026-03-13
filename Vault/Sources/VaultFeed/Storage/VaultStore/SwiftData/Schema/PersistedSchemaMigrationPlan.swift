import Foundation
import SwiftData

enum PersistedSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PersistedSchemaV1.self, PersistedSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [MigrationStage.lightweight(fromVersion: PersistedSchemaV1.self, toVersion: PersistedSchemaV2.self)]
    }
}
