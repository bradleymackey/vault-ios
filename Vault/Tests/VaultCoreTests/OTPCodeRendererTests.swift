import Foundation
import TestHelpers
import XCTest
@testable import VaultCore

final class OTPCodeRendererTests: XCTestCase {
    func test_render_numberOfLength() {
        let sut = OTPCodeRenderer()

        XCTAssertEqual(sut.render(code: 1234, digits: 4), "1234")
    }

    func test_render_padsWithLeadingZeros() {
        let sut = OTPCodeRenderer()

        XCTAssertEqual(sut.render(code: 1234, digits: 4), "1234")
        XCTAssertEqual(sut.render(code: 1234, digits: 5), "01234")
        XCTAssertEqual(sut.render(code: 1234, digits: 6), "001234")
        XCTAssertEqual(sut.render(code: 1, digits: 6), "000001")
    }

    func test_render_codeTooLongTruncatesToSuffix() throws {
        let sut = OTPCodeRenderer()

        XCTAssertEqual(sut.render(code: 1, digits: 0), "")
        XCTAssertEqual(sut.render(code: 1234, digits: 0), "")
        XCTAssertEqual(sut.render(code: 1234, digits: 1), "4")
        XCTAssertEqual(sut.render(code: 1234, digits: 2), "34")
        XCTAssertEqual(sut.render(code: 1234, digits: 3), "234")
    }
}
