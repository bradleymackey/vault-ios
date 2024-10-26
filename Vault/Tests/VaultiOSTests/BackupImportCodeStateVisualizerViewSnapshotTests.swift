import Foundation
import SwiftUI
import TestHelpers
import Testing
@testable import VaultiOS

@MainActor
struct BackupImportCodeStateVisualizerViewSnapshotTests {
    @Test
    func single_notScanned() {
        let sut = BackupImportCodeStateVisualizerView(totalCount: 1, selectedIndexes: [])
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func single_scanned() {
        let sut = BackupImportCodeStateVisualizerView(totalCount: 1, selectedIndexes: [0])
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func multiple_notScanned() {
        let sut = BackupImportCodeStateVisualizerView(totalCount: 30, selectedIndexes: [])
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func multiple_partiallyScanned() {
        let sut = BackupImportCodeStateVisualizerView(totalCount: 30, selectedIndexes: [0, 7, 12, 13])
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func multiple_allScanned() {
        let sut = BackupImportCodeStateVisualizerView(totalCount: 30, selectedIndexes: (0 ..< 30).reducedToSet())
            .framedToTestDeviceSize()

        assertSnapshot(of: sut, as: .image)
    }
}
