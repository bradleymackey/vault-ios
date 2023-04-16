import Foundation

public struct TOTP {
    private let hotp: HOTP
    public let timeInterval: UInt64

    public init(hotp: HOTP, timeInterval: UInt64 = 30) {
        self.hotp = hotp
        self.timeInterval = timeInterval
    }

    public func code(epochSeconds: UInt64) throws -> UInt32 {
        let counter = epochSeconds / timeInterval
        return try hotp.code(counter: counter)
    }
}
