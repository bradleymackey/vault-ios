import Foundation
import TestHelpers
import XCTest
@testable import CryptoDocumentExporter

final class PDFContentDrawererTests: XCTestCase {
    func test_drawContent_drawsOnceIfSuccess() {
        var executions = 0
        let sut = PDFContentDrawerer {
            executions += 1
            return .success(())
        } makeNewPage: {
            // noop
        }

        sut.drawContent()

        XCTAssertEqual(executions, 1)
    }

    func test_drawContent_drawsTwiceIfFailure() {
        var executions = 0
        let sut = PDFContentDrawerer {
            executions += 1
            return .failure(.insufficientSpace)
        } makeNewPage: {
            // noop
        }

        sut.drawContent()

        XCTAssertEqual(executions, 2)
    }

    func test_drawContent_doesNotMakeNewPageOnSuccess() {
        var executions = 0
        let sut = PDFContentDrawerer {
            .success(())
        } makeNewPage: {
            executions += 1
        }

        sut.drawContent()

        XCTAssertEqual(executions, 0)
    }

    func test_drawContent_makesNewPageOnFailure() {
        var executions = 0
        let sut = PDFContentDrawerer {
            .failure(.insufficientSpace)
        } makeNewPage: {
            executions += 1
        }

        sut.drawContent()

        XCTAssertEqual(executions, 1)
    }
}
