import CryptoStorageEngine
import Foundation
import XCTest

enum OATHType: String {
    case totp
    case hotp
}

struct OATHURI {
    let scheme: String = "otpauth"
    let type: OATHType

    var absoluteString: String {
        "\(scheme)://\(type.rawValue)/"
    }
}

final class OATHURITests: XCTestCase {
    func test_scheme_otpauth() {
        let sut = makeSUT()

        XCTAssertEqual(sut.scheme, "otpauth")
    }

    func test_type_totp() {
        let sut = makeSUT(type: .totp)

        XCTAssertEqual(sut.type, .totp)
    }

    func test_type_hotp() {
        let sut = makeSUT(type: .hotp)

        XCTAssertEqual(sut.type, .hotp)
    }

    // MARK: - Helpers

    private func makeSUT(type: OATHType = .totp) -> OATHURI {
        OATHURI(type: type)
    }
}
