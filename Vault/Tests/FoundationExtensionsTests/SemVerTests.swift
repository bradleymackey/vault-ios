import Foundation
import FoundationExtensions
import TestHelpers
import Testing

struct SemVerTests {
    @Test
    func init_validString() throws {
        let semVer = try SemVer(string: "1.0.2")

        #expect(semVer.major == 1)
        #expect(semVer.minor == 0)
        #expect(semVer.patch == 2)
    }

    @Test(arguments: ["1", "1.0", "2.1", ""])
    func init_missingComponentThrows(string: String) throws {
        #expect(throws: (any Error).self) {
            try SemVer(string: string)
        }
    }

    @Test
    func init_encodesToString() throws {
        let sut = try SemVer(string: "3.4.1")

        let encoder = JSONEncoder()

        let encoded = try encoder.encode(sut)
        let string = String(data: encoded, encoding: .utf8)
        #expect(string == "\"3.4.1\"")
    }

    @Test
    func init_decodesFromString() throws {
        let sut = Data("\"1.55.444\"".utf8)

        let decoder = JSONDecoder()

        let decoded = try decoder.decode(SemVer.self, from: sut)
        #expect(decoded.stringValue == "1.55.444")
    }

    @Test(arguments: [
        ("1.0.0", "2.0.0"),
        ("2.0.0", "3.0.0"),
        ("1.0.0", "1.5.0"),
        ("1.0.0", "1.0.1"),
        ("0.0.0", "1.0.1"),
        ("1.1.0", "1.1.1"),
        ("1.1.1", "1.1.2"),
        ("1.7.1", "2.0.0"),
    ])
    func compareOrdering(first: SemVer, second: SemVer) {
        #expect(first < second)
    }

    @Test(arguments: [
        ("1.0.0", "1.0.0"),
        ("1.0.0", "1.0.1"),
        ("1.0.0", "1.2.0"),
        ("1.0.0", "1.2.1"),
    ])
    func isCompatible_trueIfSameMajor(first: SemVer, second: SemVer) {
        #expect(first.isCompatible(with: second) == true)
    }

    @Test(arguments: [
        ("1.0.0", "0.0.0"),
        ("1.0.0", "2.0.1"),
        ("1.0.0", "2.2.0"),
        ("1.0.0", "2.2.1"),
    ])
    func isCompatible_falseIfDifferentMajor(first: SemVer, second: SemVer) {
        #expect(first.isCompatible(with: second) == false)
    }
}
