import Foundation
import FoundationExtensions
import TestHelpers
import Testing

struct SemVerTests {
    @Test
    func init_fromComponents() {
        let semVer = SemVer(major: 1, minor: 2, patch: 3)

        #expect(semVer.major == 1)
        #expect(semVer.minor == 2)
        #expect(semVer.patch == 3)
    }

    @Test(arguments: [
        ("1.0.2", 1, 0, 2),
        ("1.0.0", 1, 0, 0),
        ("2.0.0", 2, 0, 0),
        ("12.13.14", 12, 13, 14),
    ])
    func init_validString(string: String, major: Int, minor: Int, patch: Int) throws {
        let semVer = try SemVer(string: string)

        #expect(semVer.major == major)
        #expect(semVer.minor == minor)
        #expect(semVer.patch == patch)
    }

    @Test
    func init_componentNotANumberThrows() throws {
        #expect(throws: (any Error).self) {
            try SemVer(string: "not.a.comp")
        }
    }

    @Test(arguments: ["1", "1.0", "2.1", ""])
    func init_missingComponentThrows(string: String) throws {
        #expect(throws: (any Error).self) {
            try SemVer(string: string)
        }
    }

    @Test(arguments: [
        ("0.0.1", "\"0.0.1\""),
        ("1.0.0", "\"1.0.0\""),
        ("3.4.1", "\"3.4.1\""),
    ])
    func init_encodesToString(string: String, expected: String) throws {
        let sut = try SemVer(string: string)

        let encoder = JSONEncoder()

        let encoded = try encoder.encode(sut)
        let string = String(data: encoded, encoding: .utf8)
        #expect(string == expected)
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
        ("0.0.0", "0.0.1"),
    ])
    func compareOrdering(first: SemVer, second: SemVer) {
        #expect(first < second)
    }

    @Test(arguments: [
        ("2.0.0", "2.0.0"),
        ("1.4.5", "1.4.5"),
        ("1.1.1", "1.1.1"),
    ])
    func compareEqual(first: SemVer, second: SemVer) {
        #expect(first == second)
    }

    @Test(arguments: [
        ("3.0.0", "2.0.0"),
        ("2.4.5", "1.4.5"),
        ("0.0.1", "0.0.0"),
    ])
    func compareGreater(first: SemVer, second: SemVer) {
        #expect(first > second)
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
