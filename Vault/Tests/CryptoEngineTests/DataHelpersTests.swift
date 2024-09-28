import Foundation
import Testing
@testable import CryptoEngine

struct DataHelpersTests {
    @Test
    func dataAsType_interpretsAsLittleEndian() {
        let data32 = Data(hex: "ffffffee")
        #expect(data32.asType(UInt32.self) == 0xEEFF_FFFF)
        let data64 = Data(hex: "ffffffffffffffee")
        #expect(data64.asType(UInt64.self) == 0xEEFF_FFFF_FFFF_FFFF)
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
