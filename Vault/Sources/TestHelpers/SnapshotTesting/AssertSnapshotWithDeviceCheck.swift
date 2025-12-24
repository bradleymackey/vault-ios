import SnapshotTesting
import UIKit

/// Expected device configuration for snapshot tests.
/// This must match the configuration specified in Vault/README.md.
private let expectedDeviceName = "iPhone 17 Pro"
private let expectedIOSVersion = "26.2"

/// Asserts that a snapshot matches a reference, but first validates the device configuration.
///
/// This function wraps SnapshotTesting's `assertSnapshot` and adds a runtime check to ensure
/// snapshot tests are running on the correct device and iOS version as specified in the README.
///
/// - Parameters:
///   - value: The value to snapshot
///   - snapshotting: The strategy for snapshotting
///   - name: An optional name for the snapshot
///   - recording: Whether to record a new snapshot
///   - timeout: The amount of time to wait for expectations
///   - fileID: The file ID (automatically captured)
///   - file: The file path (automatically captured)
///   - testName: The test name (automatically captured)
///   - line: The line number (automatically captured)
///   - column: The column number (automatically captured)
@MainActor
public func assertSnapshot<Value>(
    of value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, some Any>,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column,
) {
    assertDeviceConfiguration(fileID: fileID, file: file, line: line)

    try SnapshotTesting.assertSnapshot(
        of: value(),
        as: snapshotting,
        named: name,
        record: recording,
        timeout: timeout,
        fileID: fileID,
        file: filePath,
        testName: testName,
        line: line,
        column: column,
    )
}

/// Validates that the current device matches the expected configuration for snapshot testing.
///
/// - Throws: `fatalError` if the device name or iOS version doesn't match expectations
@MainActor
private func assertDeviceConfiguration(
    fileID _: StaticString = #fileID,
    file: StaticString = #file,
    line: UInt = #line,
) {
    let currentDevice = UIDevice.current
    let deviceName = currentDevice.name
    let systemVersion = currentDevice.systemVersion

    guard deviceName == expectedDeviceName else {
        fatalError(
            """
            ❌ Snapshot test device mismatch!
            Expected: \(expectedDeviceName)
            Actual: \(deviceName)

            Please run snapshot tests on \(expectedDeviceName) as specified in Vault/README.md
            """,
            file: file,
            line: line,
        )
    }

    guard systemVersion == expectedIOSVersion else {
        fatalError(
            """
            ❌ Snapshot test iOS version mismatch!
            Expected: iOS \(expectedIOSVersion)
            Actual: iOS \(systemVersion)

            Please run snapshot tests on iOS \(expectedIOSVersion) as specified in Vault/README.md
            """,
            file: file,
            line: line,
        )
    }
}
