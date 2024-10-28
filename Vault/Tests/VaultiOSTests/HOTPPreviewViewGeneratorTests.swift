import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeed
import XCTest
@testable import VaultiOS

final class HOTPPreviewViewGeneratorTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let repository = HOTPPreviewViewRepositoryMock()
        let timer = IntervalTimerMock()
        let (_, factory) = makeSUT(repository: repository, timer: timer)

        XCTAssertEqual(factory.makeHOTPViewCallCount, 0)
        XCTAssertEqual(timer.waitArgValues, [])
        XCTAssertEqual(repository.expireAllCallCount, 0)
        XCTAssertEqual(repository.previewViewModelCallCount, 0)
        XCTAssertEqual(repository.obfuscateForPrivacyCallCount, 0)
        XCTAssertEqual(repository.unobfuscateForPrivacyCallCount, 0)
        XCTAssertEqual(repository.incrementerViewModelCallCount, 0)
        XCTAssertEqual(repository.textToCopyForVaultItemCallCount, 0)
    }

    @MainActor
    func test_makeOTPView_generatesViews() throws {
        let repository = HOTPPreviewViewRepositoryMock()
        repository.previewViewModelHandler = { _, _ in OTPCodePreviewViewModel(
            accountName: "any",
            issuer: "any",
            color: .black,
            isLocked: false,
            fixedCodeState: .visible("123456")
        ) }
        repository.incrementerViewModelHandler = { _, _ in OTPCodeIncrementerViewModel(
            id: .new(),
            codePublisher: .init(hotpGenerator: .init(secret: .random(count: 123))),
            timer: IntervalTimerMock(),
            initialCounter: 0,
            incrementerStore: VaultStoreHOTPIncrementerMock()
        ) }
        let (sut, _) = makeSUT(repository: repository)

        let view = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @MainActor
    func test_previewActionForVaultItem_isNilIfNoTextToCopy() {
        let repository = HOTPPreviewViewRepositoryMock()
        repository.textToCopyForVaultItemHandler = { _ in nil }
        let (sut, _) = makeSUT(repository: repository)

        let action = sut.previewActionForVaultItem(id: Identifier<VaultItem>())

        XCTAssertNil(action)
    }

    @MainActor
    func test_previewActionForVaultItem_isCopyTextWhenReturned() {
        let repository = HOTPPreviewViewRepositoryMock()
        repository.textToCopyForVaultItemHandler = { _ in .init(text: "1234", requiresAuthenticationToCopy: false) }
        let (sut, _) = makeSUT(repository: repository)

        let action = sut.previewActionForVaultItem(id: .new())

        XCTAssertEqual(action, .copyText(.init(text: "1234", requiresAuthenticationToCopy: false)))
    }

    @MainActor
    func test_textToCopyForVaultItem_getsFromRepository() {
        let repository = HOTPPreviewViewRepositoryMock()
        repository.textToCopyForVaultItemHandler = { _ in .init(text: "1234", requiresAuthenticationToCopy: false) }
        let (sut, _) = makeSUT(repository: repository)

        let action = sut.textToCopyForVaultItem(id: .new())

        XCTAssertEqual(action, .init(text: "1234", requiresAuthenticationToCopy: false))
    }

    @MainActor
    func test_scenePhaseDidChange_backgroundExpiresAll() {
        let repository = HOTPPreviewViewRepositoryMock()
        let (sut, _) = makeSUT(repository: repository)

        sut.scenePhaseDidChange(to: .background)

        XCTAssertEqual(repository.expireAllCallCount, 1)
        XCTAssertEqual(repository.unobfuscateForPrivacyCallCount, 0)
        XCTAssertEqual(repository.obfuscateForPrivacyCallCount, 0)
    }

    @MainActor
    func test_scenePhaseDidChange_inactiveObfuscatesAll() {
        let repository = HOTPPreviewViewRepositoryMock()
        let (sut, _) = makeSUT(repository: repository)

        sut.scenePhaseDidChange(to: .inactive)

        XCTAssertEqual(repository.expireAllCallCount, 0)
        XCTAssertEqual(repository.unobfuscateForPrivacyCallCount, 0)
        XCTAssertEqual(repository.obfuscateForPrivacyCallCount, 1)
    }

    @MainActor
    func test_scenePhaseDidChange_activeUnobfuscatesAll() {
        let repository = HOTPPreviewViewRepositoryMock()
        let (sut, _) = makeSUT(repository: repository)

        sut.scenePhaseDidChange(to: .active)

        XCTAssertEqual(repository.expireAllCallCount, 0)
        XCTAssertEqual(repository.unobfuscateForPrivacyCallCount, 1)
        XCTAssertEqual(repository.obfuscateForPrivacyCallCount, 0)
    }
}

extension HOTPPreviewViewGeneratorTests {
    private typealias SUT = HOTPPreviewViewGenerator<HOTPPreviewViewFactoryMock>
    @MainActor
    private func makeSUT(
        repository: HOTPPreviewViewRepositoryMock = HOTPPreviewViewRepositoryMock(),
        timer _: IntervalTimerMock = IntervalTimerMock()
    ) -> (SUT, HOTPPreviewViewFactoryMock) {
        let factory = HOTPPreviewViewFactoryMock()
        factory.makeHOTPViewHandler = { _, _, _ in AnyView(Color.green) }
        let sut = HOTPPreviewViewGenerator(viewFactory: factory, repository: repository)
        return (sut, factory)
    }

    private func anyHOTPCode() -> HOTPAuthCode {
        let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
        return .init(data: codeData)
    }

    @MainActor
    private func collectCodePreviewViewModels(
        sut: SUT,
        factory: HOTPPreviewViewFactoryMock,
        ids: [Identifier<VaultItem>],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [OTPCodePreviewViewModel] {
        var viewModels = [OTPCodePreviewViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewHandler = { viewModel, _, _ in
            viewModels.append(viewModel)
            group.leave()
            return AnyView(Text("Hello, HOTP!"))
        }

        for id in ids {
            group.enter()
            _ = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)
        }

        _ = group.wait(timeout: .now() + .seconds(1))

        XCTAssertEqual(
            viewModels.count,
            ids.count,
            "Invariant failed, expected number of view models to match the number of IDs we requested",
            file: file,
            line: line
        )
        return viewModels
    }
}
