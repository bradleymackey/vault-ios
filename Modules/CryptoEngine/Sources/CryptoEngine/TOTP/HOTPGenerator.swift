import BigInt
import CryptoSwift
import Foundation

/// # HMAC-based one-time password
///
/// HMAC-based one-time password (HOTP) is a one-time password (OTP) algorithm based on HMAC.
///
/// https://en.wikipedia.org/wiki/HMAC-based_one-time_password
public struct HOTPGenerator {
    public enum Algorithm {
        case sha1
        case sha256
        case sha512
    }

    public let secret: Data
    public let digits: UInt16
    public let algorithm: Algorithm
    private let hmac: HMAC

    public init(secret: Data, digits: UInt16 = 6, algorithm: Algorithm = .sha1) {
        self.secret = secret
        self.digits = digits
        self.algorithm = algorithm
        hmac = HMAC(key: secret.bytes, variant: algorithm.hmacVariant)
    }

    /// Generate the HOTP code using the current counter value.
    ///
    /// - Throws: only if an internal authentication error occurs.
    public func code(counter: UInt64) throws -> BigUInt {
        // truncate(MAC) = extract31(MAC, MAC[(19 × 8 + 4):(19 × 8 + 7)])
        let code = try hmacCode(counter: counter)
        // HOTP(K, C) = truncate(HMACH(K, C))
        let value = try BigUInt(truncatedHMAC(hmacCode: code))
        // HOTP value = HOTP(K, C) mod 10^d
        return value % BigUInt(10).power(Int(digits))
    }

    /// Verify that the provided `value` is expected for the given `counter` value.
    ///
    /// - Throws: only if an an internal authentication error occurs.
    public func verify(counter: UInt64, value: BigUInt) throws -> Bool {
        let expectedValue = try code(counter: counter)
        return value == expectedValue
    }
}

// MARK: - Helpers

extension HOTPGenerator {
    private func truncatedHMAC(hmacCode: Data) throws -> UInt32 {
        let offset = Int((hmacCode.last ?? 0x00) & 0x0F)
        let truncatedHMAC = Array(hmacCode[offset ... offset + 3])
        let int32HMAC = Data(truncatedHMAC).asType(UInt32.self).bigEndian
        return int32HMAC & 0x7FFF_FFFF
    }

    private func hmacCode(counter: UInt64) throws -> Data {
        let counterBytes = counter.bigEndian.data.bytes
        let bytes = try hmac.authenticate(counterBytes)
        return Data(bytes)
    }
}

extension HOTPGenerator.Algorithm {
    fileprivate var hmacVariant: HMAC.Variant {
        switch self {
        case .sha1:
            .sha1
        case .sha256:
            .sha2(.sha256)
        case .sha512:
            .sha2(.sha512)
        }
    }
}
