import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class DeviceAuthenticationServiceTests: XCTestCase {
    @MainActor
    func test_canAuthenticate_withNeither() {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: false
        )
        let sut = makeSUT(policy: policy)

        XCTAssertFalse(sut.canAuthenticate)
    }

    @MainActor
    func test_canAuthenticate_withBiometrics() {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: true
        )
        let sut = makeSUT(policy: policy)

        XCTAssertTrue(sut.canAuthenticate)
    }

    @MainActor
    func test_canAuthenticate_withPasscode() {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: false
        )
        let sut = makeSUT(policy: policy)

        XCTAssertTrue(sut.canAuthenticate)
    }

    @MainActor
    func test_canAuthenticate_withBoth() {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: true
        )
        let sut = makeSUT(policy: policy)

        XCTAssertTrue(sut.canAuthenticate)
    }

    @MainActor
    func test_authenticate_noneEnabledFails() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: false
        )
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        XCTAssertEqual(result, .failure(.noAuthenticationSetup))
        XCTAssertEqual(policy.authenticateWithBiometricsCallCount, 0)
        XCTAssertEqual(policy.authenticateWithPasscodeCallCount, 0)
    }

    @MainActor
    func test_authenticate_biometricsEnabledSuccess() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: true
        )
        policy.authenticateWithBiometricsHandler = { _ in true }
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        XCTAssertEqual(result, .success(.authenticated))
        XCTAssertEqual(policy.authenticateWithBiometricsCallCount, 1)
        XCTAssertEqual(policy.authenticateWithPasscodeCallCount, 0)
    }

    @MainActor
    func test_authenticate_biometricsEnabledFailure() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: true
        )
        policy.authenticateWithBiometricsHandler = { _ in false }
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        XCTAssertEqual(result, .failure(.authenticationFailure))
        XCTAssertEqual(policy.authenticateWithBiometricsCallCount, 1)
        XCTAssertEqual(policy.authenticateWithPasscodeCallCount, 0)
    }

    @MainActor
    func test_authenticate_biometricsInternalError() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: true
        )
        policy.authenticateWithBiometricsHandler = { _ in throw anyNSError() }
        let sut = makeSUT(policy: policy)

        await XCTAssertThrowsError(try await sut.authenticate(reason: "reason"))
        XCTAssertEqual(policy.authenticateWithBiometricsCallCount, 1)
        XCTAssertEqual(policy.authenticateWithPasscodeCallCount, 0)
    }

    @MainActor
    func test_authenticate_passcodeEnabledSuccess() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: false
        )
        policy.authenticateWithPasscodeHandler = { _ in true }
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        XCTAssertEqual(result, .success(.authenticated))
        XCTAssertEqual(policy.authenticateWithBiometricsCallCount, 0)
        XCTAssertEqual(policy.authenticateWithPasscodeCallCount, 1)
    }

    @MainActor
    func test_authenticate_passcodeEnabledFailure() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: false
        )
        policy.authenticateWithPasscodeHandler = { _ in false }
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        XCTAssertEqual(result, .failure(.authenticationFailure))
        XCTAssertEqual(policy.authenticateWithBiometricsCallCount, 0)
        XCTAssertEqual(policy.authenticateWithPasscodeCallCount, 1)
    }

    @MainActor
    func test_authenticate_passcodeInternalError() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: false
        )
        policy.authenticateWithPasscodeHandler = { _ in throw anyNSError() }
        let sut = makeSUT(policy: policy)

        await XCTAssertThrowsError(try await sut.authenticate(reason: "reason"))
        XCTAssertEqual(policy.authenticateWithBiometricsCallCount, 0)
        XCTAssertEqual(policy.authenticateWithPasscodeCallCount, 1)
    }

    @MainActor
    func test_authenticate_bothEnabledAuthenticatesWithBiometrics() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: true
        )
        policy.authenticateWithBiometricsHandler = { _ in true }
        let sut = makeSUT(policy: policy)

        _ = try await sut.authenticate(reason: "reason")
        XCTAssertEqual(policy.authenticateWithBiometricsCallCount, 1)
        XCTAssertEqual(policy.authenticateWithPasscodeCallCount, 0)
    }
}

// MARK: - Helpers

extension DeviceAuthenticationServiceTests {
    @MainActor
    private func makeSUT(
        policy: DeviceAuthenticationPolicyMock = DeviceAuthenticationPolicyMock()
    ) -> DeviceAuthenticationService {
        DeviceAuthenticationService(policy: policy)
    }
}
