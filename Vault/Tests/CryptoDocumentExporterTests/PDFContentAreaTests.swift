import TestHelpers
import UIKit
import XCTest
@testable import CryptoDocumentExporter

final class PDFContentAreaTests: XCTestCase {
    func test_init_currentBoundsIsZero() {
        let sut = PDFContentArea()

        XCTAssertEqual(sut.currentBounds, .zero)
    }

    func test_init_currentBoundsIsProvidedRect() {
        let rect = CGRect(origin: .init(x: 10, y: 10), size: .init(width: 100, height: 100))
        let sut = PDFContentArea(fullSize: rect)

        XCTAssertEqual(sut.currentBounds, rect)
    }

    func test_inset_insetsCurrentBoundsByAmount() {
        let rect = CGRect(origin: .init(x: 10, y: 10), size: .init(width: 100, height: 100))
        var sut = PDFContentArea(fullSize: rect)

        let insets = UIEdgeInsets(top: 10, left: 11, bottom: 12, right: 13)
        sut.inset(by: insets)

        XCTAssertEqual(sut.currentBounds, rect.inset(by: insets))
    }

    func test_didDrawContent_hasNoEffectOnZero() {
        var sut = PDFContentArea()

        sut.didDrawContent(at: .zero)

        XCTAssertEqual(sut.currentBounds, .zero)
    }

    func test_didDrawContent_engulfsDrawnAreaVerticallyByOrigin() {
        let rect = CGRect(origin: .init(x: 10, y: 10), size: .init(width: 100, height: 100))
        var sut = PDFContentArea(fullSize: rect)

        sut.didDrawContent(at: .init(origin: .init(x: 20, y: 20), size: .zero))

        XCTAssertEqual(sut.currentBounds, .init(x: 10.0, y: 20.0, width: 100.0, height: 90.0))
    }

    func test_didDrawContent_engulfsDrawnAreaVerticallyByHeight() {
        let rect = CGRect(origin: .init(x: 10, y: 10), size: .init(width: 100, height: 100))
        var sut = PDFContentArea(fullSize: rect)

        sut.didDrawContent(at: .init(origin: .init(x: 5, y: 5), size: .init(width: 10, height: 25)))

        XCTAssertEqual(sut.currentBounds, .init(x: 10.0, y: 30.0, width: 100.0, height: 80.0))
    }

    func test_didDrawContent_hasNoEffectIfAboveCurrentArea() {
        let rect = CGRect(origin: .init(x: 10, y: 10), size: .init(width: 100, height: 100))
        var sut = PDFContentArea(fullSize: rect)

        sut.didDrawContent(at: .init(origin: .init(x: 5, y: 5), size: .zero))

        XCTAssertEqual(sut.currentBounds, rect)
    }
}
