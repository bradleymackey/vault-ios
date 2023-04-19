import Foundation

/// A generator that produces OTPs from a given timestamp.
public protocol OTPGenerator {
    func code(epochSeconds: UInt64) throws -> UInt32
}
