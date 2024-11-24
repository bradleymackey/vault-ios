import Foundation
import TestHelpers
import Testing
@testable import VaultBackup

struct EncryptedVaultCoderTests {
    @Test
    func encodeVault_encodesToExpectedFormat() throws {
        let vault = EncryptedVault(
            version: "1.2.3",
            data: Data("data".utf8),
            authentication: Data("auth".utf8),
            encryptionIV: Data("iv".utf8),
            keygenSalt: Data("keySalt".utf8),
            keygenSignature: "signature"
        )
        let sut = EncryptedVaultCoder()

        let result = try sut.encode(vault: vault)

        #expect(
            String(data: result, encoding: .utf8) == """
            {
              "ENCRYPTION_AUTH_TAG" : "YXV0aA==",
              "ENCRYPTION_DATA" : "ZGF0YQ==",
              "ENCRYPTION_IV" : "aXY=",
              "ENCRYPTION_VERSION" : "1.2.3",
              "KEYGEN_SALT" : "a2V5U2FsdA==",
              "KEYGEN_SIGNATURE" : "signature"
            }
            """
        )
    }

    @Test
    func decodeVault_decodesFromExpectedFormat() throws {
        let vaultData = Data("""
        {
          "ENCRYPTION_AUTH_TAG" : "YXV0aA==",
          "ENCRYPTION_DATA" : "ZGF0YQ==",
          "ENCRYPTION_IV" : "aXY=",
          "ENCRYPTION_VERSION" : "1.3.2",
          "KEYGEN_SALT" : "a2V5U2FsdA==",
          "KEYGEN_SIGNATURE" : "signature"
        }
        """.utf8)
        let sut = EncryptedVaultCoder()

        let result = try sut.decode(vaultData: vaultData)

        #expect(result == EncryptedVault(
            version: "1.3.2",
            data: Data("data".utf8),
            authentication: Data("auth".utf8),
            encryptionIV: Data("iv".utf8),
            keygenSalt: Data("keySalt".utf8),
            keygenSignature: "signature"
        ))
    }

    @Test
    func encodeShard_encodesToExpectedFormat() throws {
        let shard = DataShard(
            group: .init(
                id: 0,
                number: 1,
                totalNumber: 2
            ),
            data: Data("data".utf8)
        )
        let sut = EncryptedVaultCoder()

        let result = try sut.encode(shard: shard)

        #expect(
            String(data: result, encoding: .utf8) == """
            {
              "D" : "ZGF0YQ==",
              "G" : {
                "I" : 1,
                "ID" : 0,
                "N" : 2
              }
            }
            """
        )
    }

    @Test
    func decodeShard_decodesFromExpectedFormat() throws {
        let shardData = Data("""
        {"D":"ZGF0YQ==","G":{"ID":0,"I":1,"N":2}}
        """.utf8)
        let sut = EncryptedVaultCoder()

        let result = try sut.decode(dataShard: shardData)

        #expect(result == DataShard(
            group: .init(
                id: 0,
                number: 1,
                totalNumber: 2
            ),
            data: Data("data".utf8)
        ))
    }
}
