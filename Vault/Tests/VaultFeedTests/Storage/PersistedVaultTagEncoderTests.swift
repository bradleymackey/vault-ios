import Foundation
import SwiftData
import TestHelpers
import XCTest
@testable import VaultFeed

final class PersistedVaultTagEncoderTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var context: ModelContext!

    override func setUp() async throws {
        try await super.setUp()

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistedVaultItem.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDown() async throws {
        try await super.tearDown()

        context = nil
    }
}

// MARK: - Encoding

extension PersistedVaultTagEncoderTests {
    func test_encode_newItemCreatedUUID() throws {
        let sut = makeSUT()

        var seenIds = Set<UUID>()
        for _ in 1 ... 100 {
            let item = makeWritableVaultItemTag()
            let encoded = encode(sut: sut, tag: item)
            seenIds.insert(encoded.id)
        }
        XCTAssertEqual(seenIds.count, 100)
    }

    func test_encode_name() throws {
        let name = "my tag name"
        let sut = makeSUT()
        let item = makeWritableVaultItemTag(name: name)

        let encoded = encode(sut: sut, tag: item)

        XCTAssertEqual(encoded.title, name)
    }

    func test_encode_colorWithValues() throws {
        let sut = makeSUT()
        let color = VaultItemColor(red: 0.5, green: 0.6, blue: 0.7)
        let item = makeWritableVaultItemTag(color: color)

        let encoded = encode(sut: sut, tag: item)

        XCTAssertEqual(encoded.color?.red, 0.5)
        XCTAssertEqual(encoded.color?.green, 0.6)
        XCTAssertEqual(encoded.color?.blue, 0.7)
    }

    func test_encode_iconName() throws {
        let name = "my icon name"
        let sut = makeSUT()
        let item = makeWritableVaultItemTag(iconName: name)

        let encoded = encode(sut: sut, tag: item)

        XCTAssertEqual(encoded.iconName, name)
    }
}

// MARK: - Helpers

extension PersistedVaultTagEncoderTests {
    private func makeSUT() -> PersistedVaultTagEncoder {
        PersistedVaultTagEncoder(context: context)
    }

    private func encode(
        sut: PersistedVaultTagEncoder,
        tag: VaultItemTag.Write,
        existing: PersistedVaultTag? = nil
    ) -> PersistedVaultTag {
        let tag = sut.encode(tag: tag, existing: existing)
        context.insert(tag)
        return tag
    }

    private func makeWritableVaultItemTag(
        name: String = "Any",
        color: VaultItemColor = .tagDefault,
        iconName: String = VaultItemTag.defaultIconName
    ) -> VaultItemTag.Write {
        .init(
            name: name,
            color: color,
            iconName: iconName
        )
    }

    private func makeVaultItemTag(
        id: UUID = UUID(),
        name: String = "Any",
        color: VaultItemColor = .tagDefault,
        iconName: String = VaultItemTag.defaultIconName
    ) -> VaultItemTag {
        .init(
            id: .init(id: id),
            name: name,
            color: color,
            iconName: iconName
        )
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
