import Foundation
import SwiftUI
import TestHelpers
import VaultCore
import VaultFeediOS
import XCTest

@MainActor
final class GenericVaultItemPreviewViewGeneratorTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        _ = makeSUT(totp: totp, hotp: hotp)

        XCTAssertEqual(totp.calledMethods, [])
        XCTAssertEqual(hotp.calledMethods, [])
    }

    func test_makeOTPView_makesTOTPViewForTOTP() throws {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp)

        let code = OTPAuthCode(type: .totp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(id: UUID(), item: .otpCode(code), behaviour: .normal)

        let text = try view.inspect().text().string()
        XCTAssertEqual(text, "TOTP")
    }

    func test_makeOTPView_makesHOTPViewForHOTP() throws {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp)

        let code = OTPAuthCode(type: .hotp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(id: UUID(), item: .otpCode(code), behaviour: .normal)

        let text = try view.inspect().text().string()
        XCTAssertEqual(text, "HOTP")
    }

    func test_scenePhaseDidChange_callsOnAllCollaborators() {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp)

        sut.scenePhaseDidChange(to: .active)

        XCTAssertEqual(totp.calledMethods, ["scenePhaseDidChange(to:)"])
        XCTAssertEqual(hotp.calledMethods, ["scenePhaseDidChange(to:)"])
    }

    func test_didAppear_callsOnAllCollaborators() {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp)

        sut.didAppear()

        XCTAssertEqual(totp.calledMethods, ["didAppear()"])
        XCTAssertEqual(hotp.calledMethods, ["didAppear()"])
    }
}

extension GenericVaultItemPreviewViewGeneratorTests {
    private typealias SUT = GenericVaultItemPreviewViewGenerator<MockTOTPGenerator, MockHOTPGenerator>
    private func makeSUT(
        totp: MockTOTPGenerator,
        hotp: MockHOTPGenerator
    ) -> SUT {
        GenericVaultItemPreviewViewGenerator(
            totpGenerator: totp,
            hotpGenerator: hotp
        )
    }

    private class MockHOTPGenerator: VaultItemPreviewViewGenerator, VaultItemCopyTextProvider {
        typealias PreviewItem = HOTPAuthCode
        private(set) var calledMethods = [String]()

        @MainActor
        init() {}

        func makeVaultPreviewView(id _: UUID, item _: PreviewItem, behaviour _: VaultItemViewBehaviour) -> some View {
            Text("HOTP")
        }

        func scenePhaseDidChange(to _: ScenePhase) {
            calledMethods.append(#function)
        }

        func didAppear() {
            calledMethods.append(#function)
        }

        func currentCopyableText(id _: UUID) -> String? {
            calledMethods.append(#function)
            return "some code"
        }
    }

    private class MockTOTPGenerator: VaultItemPreviewViewGenerator, VaultItemCopyTextProvider {
        typealias PreviewItem = TOTPAuthCode
        private(set) var calledMethods = [String]()

        @MainActor
        init() {}

        func makeVaultPreviewView(id _: UUID, item _: PreviewItem, behaviour _: VaultItemViewBehaviour) -> some View {
            Text("TOTP")
        }

        func scenePhaseDidChange(to _: ScenePhase) {
            calledMethods.append(#function)
        }

        func didAppear() {
            calledMethods.append(#function)
        }

        func currentCopyableText(id _: UUID) -> String? {
            calledMethods.append(#function)
            return "some code"
        }
    }
}
