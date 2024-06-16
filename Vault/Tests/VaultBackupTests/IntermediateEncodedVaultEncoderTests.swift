import Foundation
import TestHelpers
import XCTest
@testable import VaultBackup

final class IntermediateEncodedVaultEncoderTests: XCTestCase {
    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    @MainActor
    func test_encodeVault_encodesToJSONFormat_emptyVault() throws {
        let sut = makeSUT()
        let date = Date(timeIntervalSince1970: 12345)
        let backup = anyBackupPayload(
            created: date,
            userDescription: "my description",
            items: []
        )

        let encodedVault = try sut.encode(vaultBackup: backup)

        let encoded = try XCTUnwrap(String(data: encodedVault.data, encoding: .utf8))
        assertSnapshot(of: encoded, as: .lines)
    }

    @MainActor
    func test_encodeVault_encodesToJSONFormat_secureNote() throws {
        let sut = makeSUT()
        let date = Date(timeIntervalSince1970: 12345)
        let uuid = try XCTUnwrap(UUID(uuidString: "A5950174-2106-4251-BD73-58B8D39F77F3"))
        let item = VaultBackupItem(
            id: uuid,
            createdDate: date,
            updatedDate: date.addingTimeInterval(7000),
            tintColor: .init(red: 0.1, green: 0.2, blue: 0.3),
            item: .note(data: .init(title: "Example Note", rawContents: "Example note"))
        )
        let backup = anyBackupPayload(
            created: date,
            userDescription: "Example vault with a single note",
            items: [item]
        )

        let encodedVault = try sut.encode(vaultBackup: backup)

        let encoded = try XCTUnwrap(String(data: encodedVault.data, encoding: .utf8))
        assertSnapshot(of: encoded, as: .lines)
    }

    @MainActor
    func test_encodeVault_encodesToJSONFormat_otpCode() throws {
        let sut = makeSUT()
        let date = Date(timeIntervalSince1970: 12345)
        let uuid = try XCTUnwrap(UUID(uuidString: "A5950174-2106-4251-BD73-58B8D39F77F3"))
        let item = VaultBackupItem(
            id: uuid,
            createdDate: date,
            updatedDate: date.addingTimeInterval(100),
            tintColor: .init(red: 0.1, green: 0.2, blue: 0.3),
            item: .otp(data: .init(
                secretFormat: "any",
                secretData: Data(repeating: 0x41, count: 20),
                authType: "authtype",
                period: 123,
                counter: 456,
                algorithm: "algo",
                digits: 789,
                accountName: "acc",
                issuer: "iss"
            ))
        )

        let backup = anyBackupPayload(
            created: date,
            userDescription: "Example vault with a single otp code",
            items: [item]
        )

        let encodedVault = try sut.encode(vaultBackup: backup)

        let encoded = try XCTUnwrap(String(data: encodedVault.data, encoding: .utf8))
        assertSnapshot(of: encoded, as: .lines)
    }

    @MainActor
    func test_encodeVault_encodesToJSONFormat_nonEmptyVault() throws {
        let sut = makeSUT()
        let date1 = Date(timeIntervalSince1970: 12345)
        let uuid1 = try XCTUnwrap(UUID(uuidString: "A5950174-2106-4251-BD73-58B8D39F77F3"))
        let item1 = VaultBackupItem(
            id: uuid1,
            createdDate: date1,
            updatedDate: date1.addingTimeInterval(1234),
            item: .note(data: .init(title: "Hello world", rawContents: "contents of note"))
        )
        let date2 = Date(timeIntervalSince1970: 45658)
        let uuid2 = try XCTUnwrap(UUID(uuidString: "29808EAD-3727-4FF6-9B01-C5506BBDC409"))
        let item2 = VaultBackupItem(
            id: uuid2,
            createdDate: date2,
            updatedDate: date2.addingTimeInterval(1234),
            item: .note(data: .init(title: "Hello world again"))
        )
        let date3 = Date(timeIntervalSince1970: 345_652_348)
        let uuid3 = try XCTUnwrap(UUID(uuidString: "EF0849B7-C070-491B-A31B-51A11AEA26F4"))
        let item3 = VaultBackupItem(
            id: uuid3,
            createdDate: date3,
            updatedDate: date3.addingTimeInterval(100),
            tintColor: .init(red: 0.1, green: 0.2, blue: 0.3),
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
        let backup = anyBackupPayload(
            created: date1,
            userDescription: "my description again",
            items: [item1, item2, item3]
        )

        let encodedVault = try sut.encode(vaultBackup: backup)

        let encoded = try XCTUnwrap(String(data: encodedVault.data, encoding: .utf8))
        assertSnapshot(of: encoded, as: .lines)
    }
}

// MARK: - Helpers

extension IntermediateEncodedVaultEncoderTests {
    @MainActor
    private func makeSUT() -> IntermediateEncodedVaultEncoder {
        let sut = IntermediateEncodedVaultEncoder()
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
            obfuscationPadding: Data(hex: "abababa")
        )
    }
}
