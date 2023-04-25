import CryptoStorageEngine
import Foundation
import XCTest

struct TOTPURI {
    let scheme: String = "otpauth"
    let root: String = "totp"
    var parameters: [String: String] = [:]

    var absoluteString: String {
        "\(scheme)://\(root)/"
    }
}

final class TOTPURITests: XCTestCase {
    func test_scheme_otpauth() {
        let sut = makeSUT()

        XCTAssertEqual(sut.scheme, "otpauth")
    }

    func test_root_totp() {
        let sut = makeSUT()

        XCTAssertEqual(sut.root, "totp")
    }

    func test_absoluteString_noParamsHasTOTPPath() {
        let sut = makeSUT(params: [:])

        XCTAssertEqual(sut.absoluteString, "otpauth://totp/")
    }

    // MARK: - Helpers

    private func makeSUT(params _: [String: String] = [:]) -> TOTPURI {
        TOTPURI()
    }
}
