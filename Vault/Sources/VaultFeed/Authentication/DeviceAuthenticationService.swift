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

    /// Does this user even have biometrics enabled?
    public var canAuthenticate: Bool {
        policy.canAuthenticate
    }

    public func authenticate(reason: String) async throws -> Result<Success, DeviceAuthenticationFailure> {
        guard canAuthenticate else {
            return .failure(.noAuthenticationSetup)
        }

        let authenticated = try await policy.authenticate(reason: reason)
        guard authenticated else {
            return .failure(.authenticationFailure)
        }

        return .success(.authenticated)
    }
}
