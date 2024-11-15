import Foundation
import SwiftData
import TestHelpers
import Testing
@testable import VaultFeed

final class PersistedVaultTagDecoderTests {
    private let context: ModelContext

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistedVaultItem.self, configurations: config)
        context = ModelContext(container)
    }
}

// MARK: - Fields

extension PersistedVaultTagDecoderTests {
    @Test
    func decode_id() throws {
        let id = UUID()
        let item = makePersistedTag(id: id)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        #expect(decoded.id.id == id)
    }

    @Test
    func decode_name() throws {
        let name = "my tag name"
        let item = makePersistedTag(title: name)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        #expect(decoded.name == name)
    }

    @Test
    func decode_colorNilIsTagDefault() throws {
        let item = makePersistedTag(color: nil)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        #expect(decoded.color == .tagDefault)
    }

    @Test
    func decode_colorWithValues() throws {
        let color = PersistedColor(red: 0.5, green: 0.6, blue: 0.7)
        let item = makePersistedTag(color: color)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        #expect(decoded.color.red == 0.5)
        #expect(decoded.color.green == 0.6)
        #expect(decoded.color.blue == 0.7)
    }

    @Test
    func decode_iconName() throws {
        let iconName = "my icon name"
        let item = makePersistedTag(iconName: iconName)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        #expect(decoded.iconName == iconName)
    }
}

// MARK: - Helpers

extension PersistedVaultTagDecoderTests {
    private func makeSUT() -> PersistedVaultTagDecoder {
        PersistedVaultTagDecoder()
    }

    private func makePersistedTag(
        id: UUID = UUID(),
        title: String = "Any",
        color: PersistedColor? = nil,
        iconName: String? = nil
    ) -> PersistedVaultTag {
        let tag = PersistedVaultTag(id: id, title: title, color: color, iconName: iconName, items: [])
        context.insert(tag)
        return tag
    }
}
