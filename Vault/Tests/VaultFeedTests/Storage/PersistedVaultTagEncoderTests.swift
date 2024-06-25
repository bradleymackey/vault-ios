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
    func test_encode_id() throws {
        let id = UUID()
        let sut = makeSUT()
        let item = makeVaultItemTag(id: id)

        let encoded = sut.encode(tag: item)

        XCTAssertEqual(encoded.id, id)
    }

    func test_encode_name() throws {
        let name = "my tag name"
        let sut = makeSUT()
        let item = makeVaultItemTag(name: name)

        let encoded = sut.encode(tag: item)

        XCTAssertEqual(encoded.title, name)
    }

    func test_encode_colorNil() throws {
        let sut = makeSUT()
        let item = makeVaultItemTag(color: nil)

        let encoded = sut.encode(tag: item)

        XCTAssertNil(encoded.color)
    }

    func test_encode_colorWithValues() throws {
        let sut = makeSUT()
        let color = VaultItemColor(red: 0.5, green: 0.6, blue: 0.7)
        let item = makeVaultItemTag(color: color)

        let encoded = sut.encode(tag: item)

        XCTAssertEqual(encoded.color?.red, 0.5)
        XCTAssertEqual(encoded.color?.green, 0.6)
        XCTAssertEqual(encoded.color?.blue, 0.7)
    }

    func test_encode_iconName() throws {
        let name = "my icon name"
        let sut = makeSUT()
        let item = makeVaultItemTag(iconName: name)

        let encoded = sut.encode(tag: item)

        XCTAssertEqual(encoded.iconName, name)
    }
}

// MARK: - Helpers

extension PersistedVaultTagEncoderTests {
    private func makeSUT() -> PersistedVaultTagEncoder {
        PersistedVaultTagEncoder(context: context)
    }

    private func makeVaultItemTag(
        id: UUID = UUID(),
        name: String = "Any",
        color: VaultItemColor? = nil,
        iconName: String? = nil
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
