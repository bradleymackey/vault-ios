import Foundation
import TestHelpers
import XCTest
@testable import VaultCore

final class OTPCodeRendererTests: XCTestCase {
    func test_render_numberOfLength() {
        let sut = OTPCodeRenderer()

        XCTAssertEqual(try sut.render(code: 1234, digits: 4), "1234")
    }

    func test_render_padsWithLeadingZeros() {
        let sut = OTPCodeRenderer()

        XCTAssertEqual(try sut.render(code: 1234, digits: 4), "1234")
        XCTAssertEqual(try sut.render(code: 1234, digits: 5), "01234")
        XCTAssertEqual(try sut.render(code: 1234, digits: 6), "001234")
        XCTAssertEqual(try sut.render(code: 1, digits: 6), "000001")
    }

    func test_render_codeTooThrows() throws {
        let sut = OTPCodeRenderer()

        XCTAssertThrowsError(try sut.render(code: 1, digits: 0))
        XCTAssertThrowsError(try sut.render(code: 1234, digits: 0))
        XCTAssertThrowsError(try sut.render(code: 1234, digits: 1))
        XCTAssertThrowsError(try sut.render(code: 1234, digits: 2))
        XCTAssertThrowsError(try sut.render(code: 1234, digits: 3))
    }
}
