import Foundation
import SwiftData
import TestHelpers
import XCTest
@testable import VaultFeed

final class PersistedVaultItemDecoderTests: XCTestCase {
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

// MARK: - Generic

extension PersistedVaultItemDecoderTests {
    func test_decodeItem_missingItemDetail() throws {
        let sut = makeSUT()

        let persistedItem = makePersistedItem(
            noteDetails: nil,
            otpDetails: nil
        )

        XCTAssertThrowsError(try sut.decode(item: persistedItem))
    }
}

// MARK: - Metadata

extension PersistedVaultItemDecoderTests {
    func test_decodeMetadata_id() throws {
        let id = UUID()
        let item = makePersistedItem(id: id)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.id, id)
    }

    func test_decodeMetadata_createdDate() throws {
        let date = Date()
        let item = makePersistedItem(createdDate: date)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.metadata.created, date)
    }

    func test_decodeMetadata_updatedDate() throws {
        let date = Date()
        let item = makePersistedItem(updatedDate: date)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.metadata.updated, date)
    }

    func test_decodeMetadata_userDescription() throws {
        let description = "my description \(UUID().uuidString)"
        let item = makePersistedItem(userDescription: description)
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertEqual(decoded.metadata.userDescription, description)
    }

    func test_decodeMetadata_colorIsNilIfAllNil() throws {
        let item = makePersistedItem(
            colorBlue: nil,
            colorGreen: nil,
            colorRed: nil
        )
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertNil(decoded.metadata.color)
    }

    func test_decodeMetadata_colorIsNilIfAnyMissing() throws {
        let item = makePersistedItem(
            colorBlue: 0.5,
            colorGreen: nil,
            colorRed: nil
        )
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        XCTAssertNil(decoded.metadata.color)
    }

    func test_decodeMetadata_decodesColorValues() throws {
        let item = makePersistedItem(
            colorBlue: 0.5,
            colorGreen: 0.6,
            colorRed: 0.7
        )
        let sut = makeSUT()

        let decoded = try sut.decode(item: item)

        let expectedColor = VaultItemColor(red: 0.7, green: 0.6, blue: 0.5)
        XCTAssertEqual(decoded.metadata.color, expectedColor)
    }
}

// MARK: - Helpers

extension PersistedVaultItemDecoderTests {
    private func makeSUT() -> PersistedVaultItemDecoder {
        PersistedVaultItemDecoder()
    }

    private func makePersistedItem(
        id: UUID = UUID(),
        createdDate: Date = Date(),
        updatedDate: Date = Date(),
        userDescription: String? = nil,
        colorBlue: Double? = nil,
        colorGreen: Double? = nil,
        colorRed: Double? = nil,
        noteDetails: PersistedNoteDetails? = nil,
        otpDetails: PersistedOTPDetails? = .init(
            algorithm: "SHA1",
            authType: "totp",
            secretData: Data(),
            secretFormat: "BASE_32"
        )
    ) -> PersistedVaultItem {
        let item = PersistedVaultItem(
            id: id,
            createdDate: createdDate,
            updatedDate: updatedDate,
            userDescription: userDescription,
            colorBlue: colorBlue,
            colorGreen: colorGreen,
            colorRed: colorRed,
            noteDetails: noteDetails,
            otpDetails: otpDetails
        )
        context.insert(item)
        return item
    }
}
