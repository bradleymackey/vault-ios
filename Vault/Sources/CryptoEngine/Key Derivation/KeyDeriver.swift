import Foundation

/// Can derive a key, for example a KDF such as *scrypt*.
///
/// https://en.wikipedia.org/wiki/Key_derivation_function
public protocol KeyDeriver {
    func key(password: Data, salt: Data) throws -> Data
}
