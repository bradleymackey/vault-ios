import Foundation
import TestHelpers
import Testing
import VaultBackup
@testable import VaultFeed

struct VaultBackupTagEncoderTests {
    @Test
    func encode_id() {
        let sut = makeSUT()
        let id = UUID()
        let tag = VaultItemTag(id: .init(id: id), name: "my-name")

        let encoded = sut.encode(tag: tag)

        #expect(encoded.id == id)
    }

    @Test
    func encode_title() {
        let sut = makeSUT()
        let tag = VaultItemTag(id: .init(id: UUID()), name: "This is my Title")

        let encoded = sut.encode(tag: tag)

        #expect(encoded.title == "This is my Title")
    }

    @Test
    func encode_color() {
        let sut = makeSUT()
        let tag = VaultItemTag(id: .init(id: UUID()), name: "any", color: .init(red: 0.4, green: 0.5, blue: 0.6))

        let encoded = sut.encode(tag: tag)

        #expect(encoded.color?.red == 0.4)
        #expect(encoded.color?.green == 0.5)
        #expect(encoded.color?.blue == 0.6)
    }

    @Test
    func encode_iconName() {
        let sut = makeSUT()
        let tag = VaultItemTag(
            id: .init(id: UUID()),
            name: "any",
            color: .init(red: 0.4, green: 0.5, blue: 0.6),
            iconName: "icon-name"
        )

        let encoded = sut.encode(tag: tag)

        #expect(encoded.iconName == "icon-name")
    }
}

// MARK: - Helpers

extension VaultBackupTagEncoderTests {
    private func makeSUT() -> VaultBackupTagEncoder {
        .init()
    }
}
