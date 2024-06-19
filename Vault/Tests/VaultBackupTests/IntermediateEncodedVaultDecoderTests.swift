import Foundation
import XCTest
@testable import VaultBackup

final class IntermediateEncodedVaultDecoderTests: XCTestCase {
    @MainActor
    func test_decodeVault_throwsForEmptyData() {
        let sut = makeSUT()
        let data = Data()
        let vault = IntermediateEncodedVault(data: data)

        XCTAssertThrowsError(try sut.decode(encodedVault: vault))
    }

    @MainActor
    func test_decodeVault_throwsForInvalidJSON() {
        let sut = makeSUT()
        let data = Data("{}".utf8)
        let vault = IntermediateEncodedVault(data: data)

        XCTAssertThrowsError(try sut.decode(encodedVault: vault))
    }

    @MainActor
    func test_decodeVault_decodesZeroItems() throws {
        let sut = makeSUT()
        let input = VaultBackupPayload(
            version: "1.0.0",
            created: Date(timeIntervalSince1970: 1_700_575_468),
            userDescription: "my description",
            items: [],
            obfuscationPadding: Data()
        )
        let encoder = IntermediateEncodedVaultEncoder()

        let decoded = try sut.decode(encodedVault: encoder.encode(vaultBackup: input))

        XCTAssertEqual(decoded, input, "Decoded backup differs from input")
    }

    @MainActor
    func test_decodeVault_decodesNonZeroItems() throws {
        let sut = makeSUT()
        let date1 = Date(timeIntervalSince1970: 12345)
        let uuid1 = try XCTUnwrap(UUID(uuidString: "A5950174-2106-4251-BD73-58B8D39F77F3"))
        let item1 = VaultBackupItem(
            id: uuid1,
            createdDate: date1,
            updatedDate: date1.addingTimeInterval(1234),
            userDescription: "",
            visibility: .always,
            searchableLevel: .full,
            item: .note(data: .init(title: "Hello world", rawContents: "contents of note"))
        )
        let date2 = Date(timeIntervalSince1970: 45658)
        let uuid2 = try XCTUnwrap(UUID(uuidString: "29808EAD-3727-4FF6-9B01-C5506BBDC409"))
        let item2 = VaultBackupItem(
            id: uuid2,
            createdDate: date2,
            updatedDate: date2.addingTimeInterval(1234),
            userDescription: "",
            visibility: .always,
            searchableLevel: .none,
            item: .note(data: .init(title: "Hello world again"))
        )
        let date3 = Date(timeIntervalSince1970: 345_652_348)
        let uuid3 = try XCTUnwrap(UUID(uuidString: "EF0849B7-C070-491B-A31B-51A11AEA26F4"))
        let item3 = VaultBackupItem(
            id: uuid3,
            createdDate: date3,
            updatedDate: date3.addingTimeInterval(100),
            userDescription: "",
            visibility: .onlySearch,
            searchableLevel: .onlyTitle,
            searchPassphrase: "phrase",
            item: .otp(data: .init(
                secretFormat: "any",
                secretData: Data(repeating: 0xFE, count: 20),
                authType: "authtype",
                period: 123,
                counter: 456,
                algorithm: "algo",
                digits: 789,
                accountName: "acc",
                issuer: "iss"
            ))
        )
        let input = anyBackupPayload(
            created: date1,
            userDescription: "my description again",
            items: [item1, item2, item3]
        )
        let encoder = IntermediateEncodedVaultEncoder()

        let decoded = try sut.decode(encodedVault: encoder.encode(vaultBackup: input))

        XCTAssertEqual(decoded, input, "Decoded backup differs from input")
    }
}

// MARK: - Helpers

extension IntermediateEncodedVaultDecoderTests {
    @MainActor
    private func makeSUT() -> IntermediateEncodedVaultDecoder {
        let sut = IntermediateEncodedVaultDecoder()
        trackForMemoryLeaks(sut)
        return sut
    }

    private func anyBackupPayload(
        created: Date = Date(),
        userDescription: String = "my description",
        items: [VaultBackupItem] = []
    ) -> VaultBackupPayload {
        VaultBackupPayload(
            version: "1.0.0",
            created: created,
            userDescription: userDescription,
            items: items,
            obfuscationPadding: Data()
        )
    }
}
