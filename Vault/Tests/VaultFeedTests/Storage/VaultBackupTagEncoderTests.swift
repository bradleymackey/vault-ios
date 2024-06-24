import Foundation
import TestHelpers
import VaultBackup
import XCTest
@testable import VaultFeed

final class VaultBackupTagEncoderTests: XCTestCase {
    func test_encode_id() {
        let sut = makeSUT()
        let id = UUID()
        let tag = VaultItemTag(id: .init(id: id), name: "my-name")

        let encoded = sut.encode(tag: tag)

        XCTAssertEqual(encoded.id, id)
    }

    func test_encode_title() {
        let sut = makeSUT()
        let tag = VaultItemTag(id: .init(id: UUID()), name: "This is my Title")

        let encoded = sut.encode(tag: tag)

        XCTAssertEqual(encoded.title, "This is my Title")
    }

    func test_encode_color() {
        let sut = makeSUT()
        let tag = VaultItemTag(id: .init(id: UUID()), name: "any", color: .init(red: 0.4, green: 0.5, blue: 0.6))

        let encoded = sut.encode(tag: tag)

        XCTAssertEqual(encoded.color?.red, 0.4)
        XCTAssertEqual(encoded.color?.green, 0.5)
        XCTAssertEqual(encoded.color?.blue, 0.6)
    }

    func test_encode_iconName() {
        let sut = makeSUT()
        let tag = VaultItemTag(
            id: .init(id: UUID()),
            name: "any",
            color: .init(red: 0.4, green: 0.5, blue: 0.6),
            iconName: "icon-name"
        )

        let encoded = sut.encode(tag: tag)

        XCTAssertEqual(encoded.iconName, "icon-name")
    }
}

// MARK: - Helpers

extension VaultBackupTagEncoderTests {
    private func makeSUT() -> VaultBackupTagEncoder {
        .init()
    }
}
