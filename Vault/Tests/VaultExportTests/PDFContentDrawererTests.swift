import Foundation
import TestHelpers
import Testing
@testable import VaultExport

struct PDFContentDrawererTests {
    @Test
    func drawContent_drawsOnceIfSuccess() async throws {
        try await confirmation { confirmation in
            let sut = PDFContentDrawerer {
                defer { confirmation.confirm() }
                return .success(.didDrawToDocument)
            } makeNewPage: {
                // noop
            }

            try sut.drawContent()
        }
    }

    @Test
    func drawContent_drawsTwiceIfInsufficientSpaceOnFirstCall() async throws {
        try await confirmation(expectedCount: 2) { confirmation in
            var hasCalled = false
            let sut = PDFContentDrawerer {
                defer { hasCalled = true }
                defer { confirmation.confirm() }
                if !hasCalled {
                    return .failure(.insufficientSpace)
                } else {
                    return .success(.didDrawToDocument)
                }
            } makeNewPage: {
                // noop
            }

            try sut.drawContent()
        }
    }

    @Test
    func drawContent_throwsErrorIfInsufficientSpaceMoreThanOnce() throws {
        let sut = PDFContentDrawerer {
            .failure(.insufficientSpace)
        } makeNewPage: {
            // noop
        }

        #expect(throws: PDFContentDrawerer.DrawError.insufficientSpace) {
            try sut.drawContent()
        }
    }

    @Test
    func drawContent_doesNotDrawTwiceIfContentMissing() async throws {
        try await confirmation(expectedCount: 1) { confirmation in
            let sut = PDFContentDrawerer {
                defer { confirmation.confirm() }
                return .failure(.contentMissing)
            } makeNewPage: {
                // noop
            }

            try sut.drawContent()
        }
    }

    @Test
    func drawContent_doesNotMakeNewPageOnSuccess() async throws {
        try await confirmation(expectedCount: 0) { confirmation in
            let sut = PDFContentDrawerer {
                .success(.didDrawToDocument)
            } makeNewPage: {
                confirmation.confirm()
            }
            try sut.drawContent()
        }
    }

    @Test
    func drawContent_makesNewPageOnInsufficientSpace() async throws {
        try await confirmation(expectedCount: 1) { confirmation in
            var hasCalled = false
            let sut = PDFContentDrawerer {
                defer { hasCalled = true }
                if !hasCalled {
                    return .failure(.insufficientSpace)
                } else {
                    return .success(.didDrawToDocument)
                }
            } makeNewPage: {
                confirmation.confirm()
            }

            try sut.drawContent()
        }
    }

    @Test
    func drawContent_doesNotMakeNewPageOnContentMissing() async throws {
        try await confirmation(expectedCount: 0) { confirmation in
            let sut = PDFContentDrawerer {
                .failure(.contentMissing)
            } makeNewPage: {
                confirmation.confirm()
            }

            try sut.drawContent()
        }
    }
}
