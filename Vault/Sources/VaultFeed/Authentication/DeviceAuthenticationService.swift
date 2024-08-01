import Foundation

/// Uses the local device to authenticate the current user.
@Observable
@MainActor
public final class DeviceAuthenticationService {
    private let policy: any DeviceAuthenticationPolicy
    public init(policy: any DeviceAuthenticationPolicy) {
        self.policy = policy
    }

    public enum Success: Sendable {
        case authenticated
    }

    public enum Failed: Error, Sendable {
        case noAuthenticationSetup
        case authenticationFailure
    }

    /// Does this user even have biometrics enabled?
    public var canAuthenticate: Bool {
        policy.canAuthenicateWithPasscode || policy.canAuthenticateWithBiometrics
    }

    public func authenticate(reason: String) async throws -> Success {
        if policy.canAuthenticateWithBiometrics {
            let success = try await policy.authenticateWithBiometrics(reason: reason)
            guard success else { throw Failed.authenticationFailure }
            return .authenticated
        }

        if policy.canAuthenicateWithPasscode {
            let success = try await policy.authenticateWithPasscode(reason: reason)
            guard success else { throw Failed.authenticationFailure }
            return .authenticated
        }

        throw Failed.noAuthenticationSetup
    }
}
