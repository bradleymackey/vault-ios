import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupPasswordDecoderTests: XCTestCase {
    func test_decode_throwsErrorIfVersionImcompatible() {
        let sut = makeSUT()

        let str = """
        {
          "KEY" : "aGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGg=",
          "KEY_DERIVER" : "vault.keygen.default.testing",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "0.0.0"
        }
        """
        let data = Data(str.utf8)

        XCTAssertThrowsError(try sut.decode(data: data))
        XCTAssertThrowsError(try sut.decode(qrCode: str))
    }

    func test_decode_throwsErrorIfKeyLengthIncorrect() {
        let sut = makeSUT()

        let str = """
        {
          "KEY" : "aGhoaGhoaGhoaA==",
          "KEY_DERIVER" : "vault.keygen.default.testing",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "1.0.0"
        }
        """
        let data = Data(str.utf8)

        XCTAssertThrowsError(try sut.decode(data: data))
        XCTAssertThrowsError(try sut.decode(qrCode: str))
    }

    func test_decode_decodesCorrectly() throws {
        let sut = makeSUT()

        let str = """
        {
          "KEY" : "aGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGg=",
          "KEY_DERIVER" : "vault.keygen.default.testing",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "1.0.0"
        }
        """
        let data = Data(str.utf8)
        let resultData = try sut.decode(data: data)
        let resultQR = try sut.decode(qrCode: str)

        XCTAssertEqual(resultData.key, .repeating(byte: 0x68))
        XCTAssertEqual(resultData.salt, Data(repeating: 0x69, count: 20))
        XCTAssertEqual(resultQR.key, .repeating(byte: 0x68))
        XCTAssertEqual(resultQR.salt, Data(repeating: 0x69, count: 20))
    }
}

// MARK: - Helpers

extension BackupPasswordDecoderTests {
    private func makeSUT() -> BackupPasswordDecoder {
        BackupPasswordDecoder()
    }
}
