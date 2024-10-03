import Foundation
import TestHelpers
import Testing
@testable import VaultBackup

struct DataShardEncodingTests {
    @Test
    func encode_codingKeysAreUpperCamelCaseAndUnchanged() throws {
        let id: UInt16 = 789
        let data = Data(hex: "0xabcd")
        let shard = DataShard(group: .init(id: id, number: 10, totalNumber: 123), data: data)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let encoded = try encoder.encode(shard)
        let string = try #require(String(data: encoded, encoding: .utf8))

        #expect(string == """
        {
          "D" : "q80=",
          "G" : {
            "I" : 10,
            "ID" : 789,
            "N" : 123
          }
        }
        """)
    }
}
