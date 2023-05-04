import Combine
import CombineTestExtensions
import CryptoEngine
import Foundation
import XCTest
@testable import OTPFeed

final class HOTPCodeRendererTests: XCTestCase {
    func test_renderedCodePublisher_publishesInitialCodeImmediately() throws {
        let sut = makeSUT()

        let publisher = sut.renderedCodePublisher()
            .record(scheduler: TestScheduler(), numberOfRecords: 1)

        let values = publisher.waitAndCollectRecords()
        XCTAssertEqual(values, [
            .value("84755224"),
        ])
    }

    func test_renderedCodePublisher_publishesCodesOnCounterChange() throws {
        let sut = makeSUT()

        let publisher = sut.renderedCodePublisher()
            .record(scheduler: TestScheduler(), numberOfRecords: 3)

        sut.set(counter: 1)
        sut.set(counter: 2)

        let values = publisher.waitAndCollectRecords()
        XCTAssertEqual(values, [
            .value("84755224"),
            .value("94287082"),
            .value("37359152"),
        ])
    }

    // MARK: - Helpers

    private func makeSUT(initialCounter: UInt64 = 0) -> HOTPCodeRenderer {
        let sut = HOTPCodeRenderer(hotpGenerator: fixedGenerator(), initialCounter: initialCounter)
        return sut
    }

    private func fixedGenerator() -> HOTPGenerator {
        HOTPGenerator(secret: hotpRfcSecretData(), digits: .eight, algorithm: .sha1)
    }
}
