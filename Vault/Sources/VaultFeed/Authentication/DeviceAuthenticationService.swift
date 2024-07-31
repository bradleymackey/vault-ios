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

    /// Does this user even have biometrics enabled?
    public var canAuthenticate: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) || context
            .canEvaluatePolicy(
                .deviceOwnerAuthentication,
                error: &error
            )
    }

    public func authenticate(reason: String) async throws -> DeviceAuthenticationSuccess {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return try await evaluate(with: .deviceOwnerAuthenticationWithBiometrics, context: context, reason: reason)
        }

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return try await evaluate(with: .deviceOwnerAuthentication, context: context, reason: reason)
        }

        return .authenticatedByDefault
    }

    private func evaluate(
        with policy: LAPolicy,
        context: LAContext,
        reason: String
    ) async throws -> DeviceAuthenticationSuccess {
        let result = try await context.evaluatePolicy(policy, localizedReason: reason)
        guard result else { throw DeviceAuthenticationFailed() }
        return .authenticated
    }
}
