import Foundation
import XCTest
@testable import CryptoEngine

final class DataHelpersTests: XCTestCase {
    func test_dataAsType_interpretsAsLittleEndian() {
        let data32 = Data(hex: "ffffffee")
        XCTAssertEqual(data32.asType(UInt32.self), 0xEEFF_FFFF)
        let data64 = Data(hex: "ffffffffffffffee")
        XCTAssertEqual(data64.asType(UInt64.self), 0xEEFF_FFFF_FFFF_FFFF)
    }

    func test_int64ToData_interpretsAsLittleEndian() {
        let number: UInt64 = 1
        XCTAssertEqual(number.data.bytes, [1, 0, 0, 0, 0, 0, 0, 0])
    }

    func test_byteString_interpretsUTF8StringValues() {
        let value = Data(byteString: "1234")
        XCTAssertEqual(value.bytes, [49, 50, 51, 52])
    }
}
