import Foundation
import Testing
@testable import CryptoEngine

struct DataHelpersTests {
    @Test(arguments: [
        ("ffffffee", 0xEEFF_FFFF),
        ("00000000", 0x0000_0000),
        ("00000001", 0x0100_0000),
        ("ffffffff", 0xFFFF_FFFF),
    ])
    func dataAsType_interpretsAsLittleEndianInt32(hex: String, expected: UInt32) {
        let data32 = Data(hex: hex)
        #expect(data32.asType(UInt32.self) == expected)
    }

    @Test(arguments: [
        ("ffffffffffffffee", 0xEEFF_FFFF_FFFF_FFFF),
        ("0000000000000000", 0x0000_0000_0000_0000),
        ("0000000000000001", 0x0100_0000_0000_0000),
        ("ffffffffffffffff", 0xFFFF_FFFF_FFFF_FFFF),
    ])
    func dataAsType_interpretsAsLittleEndianInt64(hex: String, expected: UInt64) {
        let data64 = Data(hex: hex)
        #expect(data64.asType(UInt64.self) == expected)
    }

    @Test
    func int64ToData_interpretsAsLittleEndian() {
        let number: UInt64 = 1
        #expect(number.data.bytes == [1, 0, 0, 0, 0, 0, 0, 0])
    }

    @Test
    func byteString_interpretsUTF8StringValues() {
        let value = Data(byteString: "1234")
        #expect(value.bytes == [49, 50, 51, 52])
    }
}
