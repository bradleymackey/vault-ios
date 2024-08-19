import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class PersistedSchemaMigrationPlanTests: XCTestCase {
    func test_stages_none() {
        let stages = PersistedSchemaMigrationPlan.stages

        XCTAssertEqual(stages.count, 0)
    }
}
