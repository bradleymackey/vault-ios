import Combine
import CryptoEngine
import Foundation
import XCTest
@testable import VaultFeed

final class HOTPCodeRendererTests: XCTestCase {
    @MainActor
    func test_renderedCodePublisher_doesNotPublishesInitialCodeImmediately() async throws {
        let sut = makeSUT(digits: 8)
        let publisher = sut.renderedCodePublisher().collectFirst(1)

        await awaitNoPublish(publisher: publisher, when: {
            // noop
        })
    }

    @MainActor
    func test_renderedCodePublisher_publishesCodesOnCounterChangeOnly() async throws {
        let sut = makeSUT(digits: 8)

        let publisher = sut.renderedCodePublisher().collectFirst(2)

        let values = try await awaitPublisher(publisher, when: {
            sut.set(counter: 1)
            sut.set(counter: 2)
        })
        XCTAssertEqual(values, ["94287082", "37359152"])
    }

    @MainActor
    func test_renderedCodePublisher_publishesZeroLengthCode() async throws {
        let sut = makeSUT(digits: 0)

        let publisher = sut.renderedCodePublisher().collectFirst(2)

        let values = try await awaitPublisher(publisher, when: {
            sut.set(counter: 1)
            sut.set(counter: 2)
        })
        XCTAssertEqual(values, ["", ""])
    }

    @MainActor
    func test_renderedCodePublisher_publishesCodesWithLeadingZeros() async throws {
        let sut = makeSUT(digits: 20)

        let publisher = sut.renderedCodePublisher().collectFirst(2)

        let values = try await awaitPublisher(publisher, when: {
            sut.set(counter: 1)
            sut.set(counter: 2)
        })
        XCTAssertEqual(values, ["00000000001094287082", "00000000000137359152"])
    }

    // MARK: - Helpers

    private func makeSUT(
        digits: UInt16,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HOTPCodeRenderer {
        let sut = HOTPCodeRenderer(hotpGenerator: fixedGenerator(digits: digits))
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func fixedGenerator(digits: UInt16) -> HOTPGenerator {
        HOTPGenerator(secret: hotpRfcSecretData(), digits: digits, algorithm: .sha1)
    }
}
