import Foundation
import LocalAuthentication

/// @mockable
public protocol DeviceAuthenticationPolicy: Sendable {
    var canAuthenicateWithPasscode: Bool { get }
    var canAuthenticateWithBiometrics: Bool { get }
    func authenticateWithBiometrics(reason: String) async throws -> Bool
    func authenticateWithPasscode(reason: String) async throws -> Bool
}

// MARK: - Implementations

public struct DeviceAuthenticationPolicyAlwaysDeny: DeviceAuthenticationPolicy {
    public init() {}

    public var canAuthenicateWithPasscode: Bool { true }
    public var canAuthenticateWithBiometrics: Bool { true }

    public func authenticateWithPasscode(reason _: String) async throws -> Bool {
        false
    }

    public func authenticateWithBiometrics(reason _: String) async throws -> Bool {
        false
    }
}

extension DeviceAuthenticationPolicy where Self == DeviceAuthenticationPolicyAlwaysDeny {
    public static var alwaysDeny: Self { .init() }
}

public struct DeviceAuthenticationPolicyAlwaysAllow: DeviceAuthenticationPolicy {
    public init() {}

    public var canAuthenicateWithPasscode: Bool { true }
    public var canAuthenticateWithBiometrics: Bool { true }

    public func authenticateWithPasscode(reason _: String) async throws -> Bool {
        true
    }

    public func authenticateWithBiometrics(reason _: String) async throws -> Bool {
        true
    }
}

extension DeviceAuthenticationPolicy where Self == DeviceAuthenticationPolicyAlwaysAllow {
    public static var alwaysAllow: Self { .init() }
}

/// `DeviceAuthenticationPolicy` using `LocalAuthentication`.
///
/// This uses the configuration for the current device. If no local authentication is available (because the user has no
/// authentication setup for their device), succeed anyway.
public struct DeviceAuthenticationPolicyUsingDevice: DeviceAuthenticationPolicy {
    public init() {}

    public var canAuthenicateWithPasscode: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        )
    }

    public var canAuthenticateWithBiometrics: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }

    public func authenticateWithPasscode(reason: String) async throws -> Bool {
        let context = LAContext()
        return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }

    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        let context = LAContext()
        return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
}

extension DeviceAuthenticationPolicy where Self == DeviceAuthenticationPolicyUsingDevice {
    public static var `default`: Self { .init() }
    public static var usingDevice: Self { .init() }
}
