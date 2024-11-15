import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

struct PersistedSchemaMigrationPlanTests {
    @Test
    func stages_none() {
        let stages = PersistedSchemaMigrationPlan.stages

        #expect(stages.isEmpty)
    }
}
