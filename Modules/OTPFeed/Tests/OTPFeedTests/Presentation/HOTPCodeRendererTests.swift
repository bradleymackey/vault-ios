import Combine
import CryptoEngine
import Foundation
import XCTest
@testable import OTPFeed

final class HOTPCodeRendererTests: XCTestCase {
    func test_renderedCodePublisher_doesNotPublishesInitialCodeImmediately() async throws {
        let sut = makeSUT()
        let publisher = sut.renderedCodePublisher().collectFirst(1)

        await awaitNoPublish(publisher: publisher, when: {
            // noop
        })
    }

    func test_renderedCodePublisher_publishesCodesOnCounterChangeOnly() async throws {
        let sut = makeSUT()

        let publisher = sut.renderedCodePublisher().collectFirst(2)

        let values = try await awaitPublisher(publisher, when: {
            sut.set(counter: 1)
            sut.set(counter: 2)
        })
        XCTAssertEqual(values, ["94287082", "37359152"])
    }

    // MARK: - Helpers

    private func makeSUT(
        initialCounter _: UInt64 = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HOTPCodeRenderer {
        let sut = HOTPCodeRenderer(hotpGenerator: fixedGenerator())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func fixedGenerator() -> HOTPGenerator {
        HOTPGenerator(secret: hotpRfcSecretData(), digits: .eight, algorithm: .sha1)
    }
}
