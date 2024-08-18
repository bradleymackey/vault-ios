import Foundation
import TestHelpers
import VaultBackup
import XCTest
@testable import VaultFeed

final class VaultBackupTagDecoderTests: XCTestCase {
    func test_decode_id() throws {
        let id = UUID()
        let sut = makeSUT()
        let item = VaultBackupTag(id: id, title: "my-title", color: nil, iconName: "my-icon-name")

        let decoded = try sut.decode(tag: item)

        XCTAssertEqual(decoded.id.id, id)
    }

    func test_decode_name() throws {
        let sut = makeSUT()
        let item = VaultBackupTag(id: UUID(), title: "my-title", color: nil, iconName: "my-icon-name")

        let decoded = try sut.decode(tag: item)

        XCTAssertEqual(decoded.name, "my-title")
    }

    func test_decode_color() throws {
        let sut = makeSUT()
        let color = VaultBackupRGBColor(red: 0.4, green: 0.5, blue: 0.6)
        let item = VaultBackupTag(id: UUID(), title: "my-title", color: color, iconName: "my-icon-name")

        let decoded = try sut.decode(tag: item)

        XCTAssertEqual(decoded.color.red, 0.4)
        XCTAssertEqual(decoded.color.green, 0.5)
        XCTAssertEqual(decoded.color.blue, 0.6)
    }

    func test_decode_iconName() throws {
        let sut = makeSUT()
        let item = VaultBackupTag(id: UUID(), title: "any", color: nil, iconName: "my-icon-name")

        let decoded = try sut.decode(tag: item)

        XCTAssertEqual(decoded.iconName, "my-icon-name")
    }
}

// MARK: - Helpers

extension VaultBackupTagDecoderTests {
    private func makeSUT() -> VaultBackupTagDecoder {
        .init()
    }
}
