import Foundation
import FoundationExtensions

/// A key deriver that is composed of a sequence of other `KeyDeriver`s
///
/// The output from the first is fed into the second, etc.
public struct CombinationKeyDeriver<Length: KeyLength>: KeyDeriver {
    private let derivers: [any KeyDeriver<Length>]

    public init(derivers: [any KeyDeriver<Length>]) {
        self.derivers = derivers
    }

    public enum KeyDeriverError: Error {
        case noKeyDerviers
    }

    public func key(password: Data, salt: Data) throws -> KeyData<Length> {
        guard let first = derivers.first else { throw KeyDeriverError.noKeyDerviers }
        let firstGeneration = try first.key(password: password, salt: salt)
        return try derivers[1...].reduce(firstGeneration) { currentKey, keyDeriver in
            try Task.checkCancellation()
            return try keyDeriver.key(password: currentKey.data, salt: salt)
        }
    }

    public var uniqueAlgorithmIdentifier: String {
        let childIdentifiers = derivers.map(\.uniqueAlgorithmIdentifier).joined(separator: "|")
        return "COMBINATION<\(childIdentifiers)>"
    }
}
