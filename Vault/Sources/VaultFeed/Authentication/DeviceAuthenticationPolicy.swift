import Foundation
import LocalAuthentication

/// @mockable
public protocol DeviceAuthenticationPolicy: Sendable {
    /// Does the device support authentication?
    var isAuthenticationEnabled: Bool { get }
    /// Attempt an authentication with the given reason.
    func authenticate(reason: String) async throws -> DeviceAuthenticationSuccess
}

public enum DeviceAuthenticationSuccess: Sendable {
    case authenticated
    case authenticatedByDefault
}

public struct DeviceAuthenticationFailed: Error, Sendable {}

// MARK: - Implementations

public struct DeviceAuthenticationPolicyAlwaysDeny: DeviceAuthenticationPolicy {
    public init() {}

    public var isAuthenticationEnabled: Bool { true }

    public func authenticate(reason _: String) async throws -> DeviceAuthenticationSuccess {
        throw DeviceAuthenticationFailed()
    }
}

extension DeviceAuthenticationPolicy where Self == DeviceAuthenticationPolicyAlwaysDeny {
    public static var alwaysDeny: Self { .init() }
}

public struct DeviceAuthenticationPolicyAlwaysAllow: DeviceAuthenticationPolicy {
    public init() {}

    public var isAuthenticationEnabled: Bool { true }

    public func authenticate(reason _: String) async throws -> DeviceAuthenticationSuccess {
        .authenticated
    }
}

extension DeviceAuthenticationPolicy where Self == DeviceAuthenticationPolicyAlwaysAllow {
    public static var alwaysAllow: Self { .init() }
}

/// `DeviceAuthenticationPolicy` using `LocalAuthentication`.
///
/// This uses the configuration for the current device. If no local authentication is available (because the user has no authentication setup for their device), succeed anyway.
public struct DeviceAuthenticationPolicyUsingDevice: DeviceAuthenticationPolicy {
    public init() {}

    public var isAuthenticationEnabled: Bool {
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

extension DeviceAuthenticationPolicy where Self == DeviceAuthenticationPolicyUsingDevice {
    public static var `default`: Self { .init() }
    public static var usingDevice: Self { .init() }
}
