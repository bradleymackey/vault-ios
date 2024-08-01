import Foundation

/// Uses the local device to authenticate the current user.
@Observable
@MainActor
public final class DeviceAuthenticationService {
    private let policy: any DeviceAuthenticationPolicy
    public init(policy: any DeviceAuthenticationPolicy) {
        self.policy = policy
    }

    /// Does this user even have biometrics enabled?
    public var canAuthenticate: Bool {
        policy.isAuthenticationEnabled
    }

    public func authenticate(reason: String) async throws -> DeviceAuthenticationSuccess {
        try await policy.authenticate(reason: reason)
    }
}
