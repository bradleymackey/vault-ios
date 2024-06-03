import Foundation

/// A key deriver that is composed of a sequence of other `KeyDeriver`s
public struct CombinationKeyDeriver: KeyDeriver {
    private let derivers: [any KeyDeriver]

    public init(derivers: [any KeyDeriver]) {
        self.derivers = derivers
    }

    public enum KeyDeriverError: Error {
        case noKeyDerviers
    }

    public func key(password: Data, salt: Data) throws -> Data {
        guard derivers.isNotEmpty else { throw KeyDeriverError.noKeyDerviers }
        return try derivers.reduce(password) { currentKey, keyDeriver in
            try Task.checkCancellation()
            return try keyDeriver.key(password: currentKey, salt: salt)
        }
    }

    public var uniqueAlgorithmIdentifier: String {
        let childIdentifiers = derivers.map(\.uniqueAlgorithmIdentifier).joined(separator: "|")
        return "COMBINATION<\(childIdentifiers)>"
    }
}
