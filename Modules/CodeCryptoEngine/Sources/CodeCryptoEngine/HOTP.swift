import CryptoSwift
import Foundation

/// "HMAC-based one-time password", a counter-based generator.
///
/// https://en.wikipedia.org/wiki/HMAC-based_one-time_password
public struct HOTP {
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

    public func code(counter: UInt64) throws -> UInt32 {
        let code = try hmacCode(counter: counter)
        let value = try truncatedHMAC(hmacCode: code)
        return value % digits.moduloValue
    }

    public func verify(counter: UInt64, value: UInt32) throws -> Bool {
        let expectedValue = try code(counter: counter)
        return value == expectedValue
    }

    private func truncatedHMAC(hmacCode: Data) throws -> UInt32 {
        let offset = Int((hmacCode.last ?? 0x00) & 0x0F)
        let truncatedHMAC = Array(hmacCode[offset ... offset + 3]).reversed()
        return Data(truncatedHMAC).asType(UInt32.self) & 0x7FFF_FFFF
    }

    private func hmacCode(counter: UInt64) throws -> Data {
        let counterBytes = counter.bigEndian.data.bytes
        let bytes = try hmac.authenticate(counterBytes)
        return Data(bytes)
    }
}

extension HOTP.Algorithm {
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

extension HOTP.Digits {
    var floatValue: Float {
        Float(rawValue)
    }

    var moduloValue: UInt32 {
        UInt32(pow(10, floatValue))
    }
}
