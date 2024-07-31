import Foundation
import LocalAuthentication

/// Uses the local device to authenticate the current user.
///
/// If no local authentication is available, succeed anyway.
///
/// @mockable
public protocol DeviceAuthenticationService {
    func authenticate(reason: String) async throws -> DeviceAuthenticationSuccess
}

public enum DeviceAuthenticationSuccess {
    case authenticated
    case authenticatedByDefault
}

public struct DeviceAuthenticationFailed: Error {}

public final class DeviceAuthenticationServiceImpl: DeviceAuthenticationService {
    public init() {}

    public func authenticate(reason: String) async throws -> DeviceAuthenticationSuccess {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .authenticatedByDefault
        }

        let result = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)

        guard result else {
            throw DeviceAuthenticationFailed()
        }

        return .authenticated
    }
}
