import Foundation
import TestHelpers
import XCTest
@testable import CryptoDocumentExporter

final class PDFContentDrawererTests: XCTestCase {
    func test_drawContent_drawsOnceIfSuccess() throws {
        var executions = 0
        let sut = PDFContentDrawerer {
            executions += 1
            return .success(.didDrawToDocument)
        } makeNewPage: {
            // noop
        }

        try sut.drawContent()

        XCTAssertEqual(executions, 1)
    }

    func test_drawContent_drawsTwiceIfInsufficientSpaceOnFirstCall() throws {
        var executions = 0
        let sut = PDFContentDrawerer {
            defer { executions += 1 }
            if executions == 0 {
                return .failure(.insufficientSpace)
            } else {
                return .success(.didDrawToDocument)
            }
        } makeNewPage: {
            // noop
        }

        try sut.drawContent()

        XCTAssertEqual(executions, 2)
    }

    func test_drawContent_throwsErrorIfInsufficientSpaceMoreThanOnce() throws {
        let sut = PDFContentDrawerer {
            .failure(.insufficientSpace)
        } makeNewPage: {
            // noop
        }

        XCTAssertThrowsError(try sut.drawContent())
    }

    func test_drawContent_doesNotDrawTwiceIfContentMissing() throws {
        var executions = 0
        let sut = PDFContentDrawerer {
            executions += 1
            return .failure(.contentMissing)
        } makeNewPage: {
            // noop
        }

        try sut.drawContent()

        XCTAssertEqual(executions, 1)
    }

    func test_drawContent_doesNotMakeNewPageOnSuccess() throws {
        var executions = 0
        let sut = PDFContentDrawerer {
            .success(.didDrawToDocument)
        } makeNewPage: {
            executions += 1
        }

        try sut.drawContent()

        XCTAssertEqual(executions, 0)
    }

    func test_drawContent_makesNewPageOnInsufficientSpace() throws {
        var executions = 0
        var drawExecutions = 0
        let sut = PDFContentDrawerer {
            defer { drawExecutions += 1 }
            if drawExecutions == 0 {
                return .failure(.insufficientSpace)
            } else {
                return .success(.didDrawToDocument)
            }
        } makeNewPage: {
            executions += 1
        }

        try sut.drawContent()

        XCTAssertEqual(executions, 1)
    }

    func test_drawContent_doesNotMakeNewPageOnContentMissing() throws {
        var executions = 0
        let sut = PDFContentDrawerer {
            .failure(.contentMissing)
        } makeNewPage: {
            executions += 1
        }

        try sut.drawContent()

        XCTAssertEqual(executions, 0)
    }
}
