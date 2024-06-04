import Foundation
import FoundationExtensions
import TestHelpers
import XCTest

final class SemVerTests: XCTestCase {
    func test_init_validString() throws {
        let semVer = try SemVer(string: "1.0.2")

        XCTAssertEqual(semVer.major, 1)
        XCTAssertEqual(semVer.minor, 0)
        XCTAssertEqual(semVer.patch, 2)
    }

    func test_init_missingComponentThrows() throws {
        XCTAssertThrowsError(try SemVer(string: "1.0"))
    }

    func test_init_missingTwoComponentsThrows() throws {
        XCTAssertThrowsError(try SemVer(string: "1"))
    }

    func test_init_encodesToString() throws {
        let sut = try SemVer(string: "3.4.1")

        let encoder = JSONEncoder()

        let encoded = try encoder.encode(sut)
        let string = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(string, "\"3.4.1\"")
    }

    func test_init_decodesFromString() throws {
        let sut = Data("\"1.55.444\"".utf8)

        let decoder = JSONDecoder()

        let decoded = try decoder.decode(SemVer.self, from: sut)
        XCTAssertEqual(decoded.stringValue, "1.55.444")
    }

    func test_compare() {
        let values: [(SemVer, SemVer)] = [
            ("1.0.0", "2.0.0"),
            ("2.0.0", "3.0.0"),
            ("1.0.0", "1.5.0"),
            ("1.0.0", "1.0.1"),
            ("0.0.0", "1.0.1"),
            ("1.1.0", "1.1.1"),
            ("1.1.1", "1.1.2"),
            ("1.7.1", "2.0.0"),
        ]
        for (first, second) in values {
            XCTAssertLessThan(first, second)
        }
    }

    func test_isCompatible_trueIfSameMajor() {
        XCTAssertTrue(SemVer("1.0.0").isCompatible(with: SemVer("1.0.0")))
        XCTAssertTrue(SemVer("1.0.0").isCompatible(with: SemVer("1.0.1")))
        XCTAssertTrue(SemVer("1.0.0").isCompatible(with: SemVer("1.2.0")))
        XCTAssertTrue(SemVer("1.0.0").isCompatible(with: SemVer("1.2.1")))
    }

    func test_isCompatible_trueIfDifferentMajor() {
        XCTAssertFalse(SemVer("1.0.0").isCompatible(with: SemVer("0.0.0")))
        XCTAssertFalse(SemVer("1.0.0").isCompatible(with: SemVer("2.0.1")))
        XCTAssertFalse(SemVer("1.0.0").isCompatible(with: SemVer("2.2.0")))
        XCTAssertFalse(SemVer("1.0.0").isCompatible(with: SemVer("2.2.1")))
    }
}
