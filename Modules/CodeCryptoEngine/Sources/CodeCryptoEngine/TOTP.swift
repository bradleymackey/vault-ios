import Foundation

/// # Time-based one-time password
///
/// Time-based one-time password (TOTP) is a computer algorithm that generates a one-time password (OTP) that uses the current time as a source of uniqueness.
///
/// https://en.wikipedia.org/wiki/Time-based_one-time_password
public struct TOTP {
    private let hotp: HOTP
    public let timeInterval: UInt64

    public init(hotp: HOTP, timeInterval: UInt64 = 30) {
        self.hotp = hotp
        self.timeInterval = timeInterval
    }

    /// Generate the TOTP code using the number of seconds since the UNIX epoch.
    ///
    /// - Throws: only if an internal authentication error occurs.
    public func code(epochSeconds: UInt64) throws -> UInt32 {
        let counter = epochSeconds / timeInterval
        return try hotp.code(counter: counter)
    }

    public func verify(epochSeconds: UInt64, value: UInt32) throws -> Bool {
        let expected = try code(epochSeconds: epochSeconds)
        return expected == value
    }
}
