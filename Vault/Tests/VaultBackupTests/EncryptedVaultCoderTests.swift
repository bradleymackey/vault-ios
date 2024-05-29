import Foundation
import TestHelpers
import XCTest
@testable import VaultBackup

final class EncryptedVaultCoderTests: XCTestCase {
    func test_encodeVault_encodesToExpectedFormat() throws {
        let vault = EncryptedVault(
            data: Data("data".utf8),
            authentication: Data("auth".utf8),
            encryptionIV: Data("iv".utf8)
        )
        let sut = EncryptedVaultCoder()

        let result = try sut.encode(vault: vault)

        XCTAssertEqual(
            String(data: result, encoding: .utf8),
            """
            {
              "ENCRYPTED_DATA" : "ZGF0YQ==",
              "ENCRYPTION_AUTHENTICATION" : "YXV0aA==",
              "ENCRYPTION_IV" : "aXY="
            }
            """
        )
    }

    func test_decodeVault_decodesFromExpectedFormat() {
        let vaultData = Data("""
        {"ENCRYPTED_DATA":"ZGF0YQ==","ENCRYPTION_AUTHENTICATION":"YXV0aA==","ENCRYPTION_IV":"aXY="}
        """.utf8)
        let sut = EncryptedVaultCoder()

        let result = try? sut.decode(vaultData: vaultData)

        XCTAssertEqual(result, EncryptedVault(
            data: Data("data".utf8),
            authentication: Data("auth".utf8),
            encryptionIV: Data("iv".utf8)
        ))
    }

    func test_encodeShard_encodesToExpectedFormat() throws {
        let shard = DataShard(
            group: .init(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                number: 1,
                totalNumber: 2
            ),
            data: Data("data".utf8)
        )
        let sut = EncryptedVaultCoder()

        let result = try sut.encode(shard: shard)

        XCTAssertEqual(
            String(data: result, encoding: .utf8),
            """
            {
              "DATA" : "ZGF0YQ==",
              "GROUP" : {
                "ID" : "00000000-0000-0000-0000-000000000000",
                "NUM" : 1,
                "TOT_NUM" : 2
              }
            }
            """
        )
    }

    func test_decodeShard_decodesFromExpectedFormat() {
        let shardData = Data("""
        {"DATA":"ZGF0YQ==","GROUP":{"ID":"00000000-0000-0000-0000-000000000000","NUM":1,"TOT_NUM":2}}
        """.utf8)
        let sut = EncryptedVaultCoder()

        let result = try? sut.decode(dataShard: shardData)

        XCTAssertEqual(result, DataShard(
            group: .init(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                number: 1,
                totalNumber: 2
            ),
            data: Data("data".utf8)
        ))
    }
}
