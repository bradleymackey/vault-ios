import CryptoSwift
import Foundation

/// # HMAC-based one-time password
///
/// HMAC-based one-time password (HOTP) is a one-time password (OTP) algorithm based on HMAC.
///
/// https://en.wikipedia.org/wiki/HMAC-based_one-time_password
public struct HOTPGenerator {
    public let secret: Data
    public let digits: Digits
    public let algorithm: Algorithm
    private let hmac: HMAC

    public enum Algorithm {
        case sha1
        case sha256
        case sha512
    }

    public enum Digits: Int {
        case six = 6
        case seven = 7
        case eight = 8
    }

    public init(secret: Data, digits: Digits = .six, algorithm: Algorithm = .sha1) {
        self.secret = secret
        self.digits = digits
        self.algorithm = algorithm
        hmac = HMAC(key: secret.bytes, variant: algorithm.hmacVariant)
    }

    /// Generate the HOTP code using the current counter value.
    ///
    /// - Throws: only if an internal authentication error occurs.
    public func code(counter: UInt64) throws -> UInt32 {
        let code = try hmacCode(counter: counter)
        let value = try truncatedHMAC(hmacCode: code)
        return value % digits.moduloValue
    }

    /// Verify that the provided `value` is expected for the given `counter` value.
    ///
    /// - Throws: only if an an internal authentication error occurs.
    public func verify(counter: UInt64, value: UInt32) throws -> Bool {
        let expectedValue = try code(counter: counter)
        return value == expectedValue
    }

    private func truncatedHMAC(hmacCode: Data) throws -> UInt32 {
        let offset = Int((hmacCode.last ?? 0x00) & 0x0F)
        let truncatedHMAC = Array(hmacCode[offset ... offset + 3])
        let int32HMAC = Data(
            truncatedHMAC.reversed() // asType will interpret as opposite endian-ness
        ).asType(UInt32.self)
        return int32HMAC & 0x7FFF_FFFF
    }

    private func hmacCode(counter: UInt64) throws -> Data {
        let counterBytes = counter.bigEndian.data.bytes
        let bytes = try hmac.authenticate(counterBytes)
        return Data(bytes)
    }
}

extension HOTPGenerator.Algorithm {
    var hmacVariant: HMAC.Variant {
        switch self {
        case .sha1:
            return .sha1
        case .sha256:
            return .sha2(.sha256)
        case .sha512:
            return .sha2(.sha512)
        }
    }
}

extension HOTPGenerator.Digits {
    var floatValue: Float {
        Float(rawValue)
    }

    var moduloValue: UInt32 {
        UInt32(pow(10, floatValue))
    }
}
