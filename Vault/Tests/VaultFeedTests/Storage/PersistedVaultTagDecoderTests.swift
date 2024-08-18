import Foundation
import SwiftData
import TestHelpers
import XCTest
@testable import VaultFeed

final class PersistedVaultTagDecoderTests: XCTestCase {
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

// MARK: - Fields

extension PersistedVaultTagDecoderTests {
    func test_decode_id() throws {
        let id = UUID()
        let item = makePersistedTag(id: id)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.id.id, id)
    }

    func test_decode_name() throws {
        let name = "my tag name"
        let item = makePersistedTag(title: name)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.name, name)
    }

    func test_decode_colorNilIsTagDefault() throws {
        let item = makePersistedTag(color: nil)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.color, .tagDefault)
    }

    func test_decode_colorWithValues() throws {
        let color = PersistedColor(red: 0.5, green: 0.6, blue: 0.7)
        let item = makePersistedTag(color: color)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.color.red, 0.5)
        XCTAssertEqual(decoded.color.green, 0.6)
        XCTAssertEqual(decoded.color.blue, 0.7)
    }

    func test_decode_iconName() throws {
        let iconName = "my icon name"
        let item = makePersistedTag(iconName: iconName)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.iconName, iconName)
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
