import Foundation
import TestHelpers
import Testing
import VaultBackup
@testable import VaultFeed

struct VaultBackupTagDecoderTests {
    @Test
    func decode_id() throws {
        let id = UUID()
        let sut = makeSUT()
        let item = VaultBackupTag(id: id, title: "my-title", color: nil, iconName: "my-icon-name")

        let decoded = try sut.decode(tag: item)

        #expect(decoded.id.id == id)
    }

    @Test
    func decode_name() throws {
        let sut = makeSUT()
        let item = VaultBackupTag(id: UUID(), title: "my-title", color: nil, iconName: "my-icon-name")

        let decoded = try sut.decode(tag: item)

        #expect(decoded.name == "my-title")
    }

    @Test
    func decode_color() throws {
        let sut = makeSUT()
        let color = VaultBackupRGBColor(red: 0.4, green: 0.5, blue: 0.6)
        let item = VaultBackupTag(id: UUID(), title: "my-title", color: color, iconName: "my-icon-name")

        let decoded = try sut.decode(tag: item)

        #expect(decoded.color.red == 0.4)
        #expect(decoded.color.green == 0.5)
        #expect(decoded.color.blue == 0.6)
    }

    @Test
    func decode_iconName() throws {
        let sut = makeSUT()
        let item = VaultBackupTag(id: UUID(), title: "any", color: nil, iconName: "my-icon-name")

        let decoded = try sut.decode(tag: item)

        #expect(decoded.iconName == "my-icon-name")
    }
}

// MARK: - Helpers

extension VaultBackupTagDecoderTests {
    private func makeSUT() -> VaultBackupTagDecoder {
        .init()
    }
}
