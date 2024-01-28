import Foundation
import TestHelpers
import XCTest
@testable import VaultBackup

final class DataShardEncodingTests: XCTestCase {
    func test_encode_codingKeysAreUpperCamelCaseAndUnchanged() throws {
        let id = UUID(uuidString: "616184d6-f4b2-4f21-9b1a-0d1f266bd160")!
        let data = Data(hex: "0xabcd")
        let shard = DataShard(group: .init(id: id, number: 10, totalNumber: 123), data: data)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let encoded = try encoder.encode(shard)
        let string = try XCTUnwrap(String(data: encoded, encoding: .utf8))

        XCTAssertEqual(string, """
        {
          "DATA" : "q80=",
          "GROUP" : {
            "ID" : "616184D6-F4B2-4F21-9B1A-0D1F266BD160",
            "NUM" : 10,
            "TOT_NUM" : 123
          }
        }
        """)
    }
}
