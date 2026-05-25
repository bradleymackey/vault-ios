import Foundation
import SwiftData
import TestHelpers
import Testing
@testable import VaultFeed

struct PersistedSchemaMigrationPlanTests {
    @Test
    func stages_includesV1ToV2() {
        let stages = PersistedSchemaMigrationPlan.stages

        #expect(stages.count == 1)
    }

    @Test
    func schemas_includesV1AndV2() {
        let schemas = PersistedSchemaMigrationPlan.schemas

        // V1 → V2 is the only stage. Both versioned schemas must be
        // registered so SwiftData knows how to migrate forward.
        #expect(schemas.count == 2)
    }

    // NOTE: An end-to-end migration test that seeds a V1 store and then
    // opens it through the V2 schema would be the ideal coverage, but it
    // is not feasible in this test target: both `PersistedSchemaV1.PersistedVaultItem`
    // and `PersistedSchemaV2.PersistedVaultItem` are `@Model` classes
    // generated under the same CoreData entity name (`PersistedVaultItem`),
    // and SwiftData refuses to host both representations in the same
    // process. The migration is instead exercised by:
    //
    //   * `KillphraseRehashServiceTests` (Phase B — digest writes + clear)
    //   * `PendingKillphraseRehashStoreTests` (on-disk handoff format)
    //
    // Real V1 → V2 behaviour is covered by manual upgrade testing in CI
    // against a checked-in V1 fixture store.
}
