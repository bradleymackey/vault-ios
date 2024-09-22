import Foundation

/// Semantic Version number to indicate versioning and compatibility.
public struct SemVer: Equatable, Hashable, Sendable {
    public var major: Int
    public var minor: Int
    public var patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    struct ParseError: Error {
        var reason: String
    }

    public init(string: String) throws {
        let values = string.split(separator: ".")
        guard values.count == 3 else {
            throw ParseError(reason: "Bad number of SemVer components")
        }
        let ints = try values.map {
            if let i = Int($0) { i } else { throw ParseError(reason: "Component is not a number.") }
        }
        major = ints[0]
        minor = ints[1]
        patch = ints[2]
    }
}

extension SemVer: Codable {
    public var stringValue: String {
        "\(major).\(minor).\(patch)"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string: string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}

extension SemVer: Comparable {
    public static func < (lhs: SemVer, rhs: SemVer) -> Bool {
        if lhs.major < rhs.major { return true }
        if lhs.major == rhs.major, lhs.minor < rhs.minor { return true }
        if lhs.major == rhs.major, lhs.minor == rhs.minor, lhs.patch < rhs.patch { return true }
        return false
    }

    public func isCompatible(with other: SemVer) -> Bool {
        major == other.major
    }
}

extension SemVer: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        // It's fine to crash on an invalid literal.
        // swiftlint:disable:next force_try
        try! self.init(string: value)
    }
}
