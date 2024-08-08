import Foundation

public enum DeviceAuthenticationFailure: Error, Sendable {
    case noAuthenticationSetup
    case authenticationFailure
}
