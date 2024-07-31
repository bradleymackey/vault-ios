import Foundation
@preconcurrency import LocalAuthentication

public enum DeviceAuthenticationSuccess {
    case authenticated
    case authenticatedByDefault
}

public struct DeviceAuthenticationFailed: Error {}

/// Uses the local device to authenticate the current user.
///
/// If no local authentication is available, succeed anyway.
@Observable
@MainActor
public final class DeviceAuthenticationService {
    public init() {}

    public func authenticate(reason: String) async throws -> DeviceAuthenticationSuccess {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            guard result else {
                throw DeviceAuthenticationFailed()
            }

            return .authenticated
        }

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let result = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)

            guard result else {
                throw DeviceAuthenticationFailed()
            }

            return .authenticated
        }

        return .authenticatedByDefault
    }
}
