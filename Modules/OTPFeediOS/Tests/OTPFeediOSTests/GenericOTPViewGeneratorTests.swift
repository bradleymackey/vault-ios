import Foundation
import OTPFeediOS
import SwiftUI
import TestHelpers
import VaultCore
import XCTest

@MainActor
final class GenericOTPViewGeneratorTests: XCTestCase {
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

        let code = GenericOTPAuthCode(type: .totp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(id: UUID(), code: code, behaviour: .normal)

        let text = try view.inspect().text().string()
        XCTAssertEqual(text, "TOTP")
    }

    func test_makeOTPView_makesHOTPViewForHOTP() throws {
        let totp = MockTOTPGenerator()
        let hotp = MockHOTPGenerator()
        let sut = makeSUT(totp: totp, hotp: hotp)

        let code = GenericOTPAuthCode(type: .hotp(), data: .init(secret: .empty(), accountName: "Any"))
        let view = sut.makeVaultPreviewView(id: UUID(), code: code, behaviour: .normal)

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

extension GenericOTPViewGeneratorTests {
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
        typealias VaultItem = HOTPAuthCode
        private(set) var calledMethods = [String]()

        @MainActor
        init() {}

        func makeVaultPreviewView(id _: UUID, code _: VaultItem, behaviour _: VaultItemViewBehaviour) -> some View {
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
        typealias VaultItem = TOTPAuthCode
        private(set) var calledMethods = [String]()

        @MainActor
        init() {}

        func makeVaultPreviewView(id _: UUID, code _: VaultItem, behaviour _: VaultItemViewBehaviour) -> some View {
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
