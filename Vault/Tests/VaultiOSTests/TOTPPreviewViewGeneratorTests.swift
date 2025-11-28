import Combine
import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import XCTest
@testable import VaultiOS

final class TOTPPreviewViewGeneratorTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let repository = TOTPPreviewViewRepositoryMock()
        _ = makeSUT(factory: factory, repository: repository)

        XCTAssertEqual(factory.makeTOTPViewCallCount, 0)
        XCTAssertEqual(repository.previewViewModelCallCount, 0)
        XCTAssertEqual(repository.timerUpdaterCallCount, 0)
        XCTAssertEqual(repository.timerPeriodStateCallCount, 0)
        XCTAssertEqual(repository.stopAllTimersCallCount, 0)
        XCTAssertEqual(repository.restartAllTimersCallCount, 0)
        XCTAssertEqual(repository.textToCopyForVaultItemCallCount, 0)
        XCTAssertEqual(repository.vaultItemCacheClearCallCount, 0)
    }

    @MainActor
    func test_makeOTPView_generatesViews() throws {
        let repository = TOTPPreviewViewRepositoryMock()
        repository.previewViewModelHandler = { _, _ in
            OTPCodePreviewViewModel(
                accountName: "",
                issuer: "",
                color: .black,
                isLocked: false,
                fixedCodeState: .visible("12345"),
            )
        }
        repository.timerPeriodStateHandler = { _ in
            OTPCodeTimerPeriodState(
                statePublisher: Just(OTPCodeTimerState(currentTime: 100, period: 10))
                    .setFailureType(to: Never.self).eraseToAnyPublisher(),
            )
        }
        repository.timerUpdaterHandler = { _ in
            OTPCodeTimerUpdaterMock()
        }
        let factory = TOTPPreviewViewFactoryMock()
        factory.makeTOTPViewHandler = { _, _, _, _ in AnyView(Color.green) }
        let sut = makeSUT(factory: factory, repository: repository)

        let view = sut.makeVaultPreviewView(item: anyTOTPCode(), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_scenePhaseDidChange_activeRestartsAllTimers() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let repository = TOTPPreviewViewRepositoryMock()
        let sut = makeSUT(factory: factory, repository: repository)

        sut.scenePhaseDidChange(to: .active)

        XCTAssertEqual(repository.restartAllTimersCallCount, 1)
        XCTAssertEqual(repository.obfuscateForPrivacyCallCount, 0)
        XCTAssertEqual(repository.stopAllTimersCallCount, 0)
    }

    @MainActor
    func test_scenePhaseDidChange_inactiveAndBackgroundCancelsAllTimers() {
        let phases = [ScenePhase.background, .inactive]
        for phase in phases {
            let factory = makeTOTPPreviewViewFactoryMock()
            let repository = TOTPPreviewViewRepositoryMock()
            let sut = makeSUT(factory: factory, repository: repository)

            sut.scenePhaseDidChange(to: phase)

            XCTAssertEqual(repository.restartAllTimersCallCount, 0)
            XCTAssertEqual(repository.obfuscateForPrivacyCallCount, 1)
            XCTAssertEqual(repository.stopAllTimersCallCount, 1)
        }
    }

    @MainActor
    func test_clearViewCache_clearsRepositoryCache() async {
        let repository = TOTPPreviewViewRepositoryMock()
        let sut = makeSUT(repository: repository)

        await sut.clearViewCache()

        XCTAssertEqual(repository.vaultItemCacheClearAllCallCount, 1)
    }

    @MainActor
    func test_didAppear_restartsAllTimers() {
        let factory = makeTOTPPreviewViewFactoryMock()
        let repository = TOTPPreviewViewRepositoryMock()
        let sut = makeSUT(factory: factory, repository: repository)

        sut.didAppear()

        XCTAssertEqual(repository.restartAllTimersCallCount, 1)
        XCTAssertEqual(repository.obfuscateForPrivacyCallCount, 0)
        XCTAssertEqual(repository.stopAllTimersCallCount, 0)
    }
}

extension TOTPPreviewViewGeneratorTests {
    private typealias SUT = TOTPPreviewViewGenerator<TOTPPreviewViewFactoryMock>

    @MainActor
    private func makeSUT(
        factory: TOTPPreviewViewFactoryMock = makeTOTPPreviewViewFactoryMock(),
        repository: TOTPPreviewViewRepositoryMock = TOTPPreviewViewRepositoryMock(),
    ) -> SUT {
        SUT(viewFactory: factory, repository: repository)
    }

    private func anyTOTPCode() -> TOTPAuthCode {
        let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
        return .init(data: codeData)
    }
}

extension OTPCodeTimerUpdaterFactoryMock {
    static func defaultMock() -> OTPCodeTimerUpdaterFactoryMock {
        let s = OTPCodeTimerUpdaterFactoryMock()
        s.makeUpdaterHandler = { _ in
            MainActor.assumeIsolated {
                OTPCodeTimerUpdaterMock()
            }
        }
        return s
    }
}

@MainActor
private func makeTOTPPreviewViewFactoryMock() -> TOTPPreviewViewFactoryMock {
    let mock = TOTPPreviewViewFactoryMock()
    mock.makeTOTPViewHandler = { _, _, _, _ in AnyView(Text("Nice")) }
    return mock
}
