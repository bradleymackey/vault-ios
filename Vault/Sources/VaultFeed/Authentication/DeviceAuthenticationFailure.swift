import Foundation

public enum DeviceAuthenticationFailure: Error, Equatable, Sendable {
    case noAuthenticationSetup
    case authenticationFailure
}
