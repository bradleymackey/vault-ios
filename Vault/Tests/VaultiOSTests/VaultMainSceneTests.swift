import Foundation
import SwiftUI
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct VaultMainSceneTests {
    @Test
    func init_createsWithoutCrashing() {
        let scene = VaultMainScene()
        _ = scene.body
    }
}
