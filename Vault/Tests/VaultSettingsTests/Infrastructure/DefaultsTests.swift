//
//  DefaultsTests.swift
//
//  Copyright (c) 2017 - 2018 Nuno Manuel Dias
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import TestHelpers
import XCTest
@testable import VaultSettings

final class DefaultsKitTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var defaults: Defaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let ephemeralDefaults = try XCTUnwrap(UserDefaults(suiteName: #file))
        ephemeralDefaults.removePersistentDomain(forName: #file)
        defaults = Defaults(userDefaults: ephemeralDefaults)
    }

    override func tearDown() {
        super.tearDown()
        defaults = nil
    }

    func testInteger() throws {
        let value = 123

        try defaults.set(value, for: .integerKey)

        let hasKey = defaults.has(.integerKey)
        XCTAssertTrue(hasKey)

        let savedValue = defaults.get(for: .integerKey)
        XCTAssertEqual(savedValue, value)
    }

    func testFloat() throws {
        let value: Float = 123.1

        try defaults.set(value, for: .floatKey)

        let hasKey = defaults.has(.floatKey)
        XCTAssertTrue(hasKey)

        let savedValue = defaults.get(for: .floatKey)
        XCTAssertEqual(savedValue, value)
    }

    func testDouble() throws {
        let value = 123.1

        try defaults.set(value, for: .doubleKey)

        let hasKey = defaults.has(.doubleKey)
        XCTAssertTrue(hasKey)

        let savedValue = defaults.get(for: .doubleKey)
        XCTAssertEqual(savedValue, value)
    }

    func testString() throws {
        let value = "a string"

        try defaults.set(value, for: .stringKey)

        let hasKey = defaults.has(.stringKey)
        XCTAssertTrue(hasKey)

        let savedValue = defaults.get(for: .stringKey)
        XCTAssertEqual(savedValue, value)
    }

    func testBool() throws {
        let value = true

        try defaults.set(value, for: .boolKey)

        let hasKey = defaults.has(.boolKey)
        XCTAssertTrue(hasKey)

        let savedValue = defaults.get(for: .boolKey)
        XCTAssertEqual(savedValue, value)
    }

    func testDate() throws {
        let value = Date()

        try defaults.set(value, for: .dateKey)

        let hasKey = defaults.has(.dateKey)
        XCTAssertTrue(hasKey)

        let savedValue = defaults.get(for: .dateKey)
        XCTAssertEqual(savedValue, value)
    }

    func testEnum() throws {
        let value = EnumMock.three

        try defaults.set(value, for: .enumKey)

        let hasKey = defaults.has(.enumKey)
        XCTAssert(hasKey)

        let savedValue = defaults.get(for: .enumKey)
        XCTAssertEqual(savedValue, value)
    }

    func testOptionSet() throws {
        let value = OptionSetMock.option3

        try defaults.set(value, for: .optionSetKey)

        let hasKey = defaults.has(.optionSetKey)
        XCTAssert(hasKey)

        let savedValue = defaults.get(for: .optionSetKey)
        XCTAssertEqual(savedValue, value)
    }

    func testSet() throws {
        let values = [1, 2, 3, 4]

        try defaults.set(values, for: .arrayOfIntegersKey)

        let hasKey = defaults.has(.arrayOfIntegersKey)
        XCTAssertTrue(hasKey)

        let savedValues = defaults.get(for: .arrayOfIntegersKey)
        XCTAssertNotNil(savedValues)
        savedValues?.forEach { value in
            XCTAssertTrue(savedValues?.contains(value) ?? false)
        }
    }

    func testClear() throws {
        let values = [1, 2, 3, 4]

        try defaults.set(values, for: .arrayOfIntegersKey)
        defaults.clear(.arrayOfIntegersKey)

        let hasKey = defaults.has(.arrayOfIntegersKey)
        XCTAssertFalse(hasKey)

        let savedValues = defaults.get(for: .arrayOfIntegersKey)
        XCTAssertNil(savedValues)
    }

    func testSetObject() throws {
        let child = PersonMock(name: "Anne Greenwell", age: 30, children: [])
        let person = PersonMock(name: "Bonnie Greenwell", age: 80, children: [child])

        try defaults.set(person, for: .personMockKey)

        let hasKey = defaults.has(.personMockKey)
        XCTAssertTrue(hasKey)

        let savedPerson = defaults.get(for: .personMockKey)
        XCTAssertEqual(savedPerson?.name, "Bonnie Greenwell")
        XCTAssertEqual(savedPerson?.age, 80)
        XCTAssertEqual(savedPerson?.children.first?.name, "Anne Greenwell")
        XCTAssertEqual(savedPerson?.children.first?.age, 30)
    }

    @MainActor
    func test_clear_didChangeDefaults() async throws {
        let publisher = defaults.defaultsDidChangePublisher().collectFirst(3)

        let values: [Void] = try await awaitPublisher(publisher) {
            defaults.clear(Key<String>("test1"))
            defaults.clear(Key<String>("test2"))
            defaults.clear(Key<String>("test3"))
        }

        XCTAssertEqual(values.count, 3)
    }

    @MainActor
    func test_removeAll_didChangeDefaults() async throws {
        let publisher = defaults.defaultsDidChangePublisher().collectFirst(3)

        let values: [Void] = try await awaitPublisher(publisher) {
            defaults.removeAll()
            defaults.removeAll()
            defaults.removeAll()
        }

        XCTAssertEqual(values.count, 3)
    }

    @MainActor
    func test_set_didChangeDefaults() async throws {
        let publisher = defaults.defaultsDidChangePublisher().collectFirst(3)

        let values: [Void] = try await awaitPublisher(publisher) {
            try defaults.set("test1", for: Key<String>("test1"))
            try defaults.set("test1", for: Key<String>("test1"))
            try defaults.set("test1", for: Key<String>("test1"))
        }

        XCTAssertEqual(values.count, 3)
    }
}

// MARK: - Helpers

extension DefaultsKey {
    fileprivate static var integerKey: Key<Int> { .init("integerKey") }
    fileprivate static var floatKey: Key<Float> { .init("floatKey") }
    fileprivate static var doubleKey: Key<Double> { .init("doubleKey") }
    fileprivate static var stringKey: Key<String> { .init("stringKey") }
    fileprivate static var boolKey: Key<Bool> { .init("boolKey") }
    fileprivate static var dateKey: Key<Date> { .init("dateKey") }
    fileprivate static var enumKey: Key<EnumMock> { .init("enumKey") }
    fileprivate static var optionSetKey: Key<OptionSetMock> { .init("optionSetKey") }
    fileprivate static var arrayOfIntegersKey: Key<[Int]> { .init("arrayOfIntegersKey") }
    fileprivate static var personMockKey: Key<PersonMock> { .init("personMockKey") }
}

struct PersonMock: Codable {
    let name: String
    let age: Int
    let children: [PersonMock]
}

private enum EnumMock: Int, Codable {
    case one, two, three
}

private struct OptionSetMock: OptionSet, Codable {
    let rawValue: Int
    static let option1 = OptionSetMock(rawValue: 1)
    static let option2 = OptionSetMock(rawValue: 2)
    static let option3 = OptionSetMock(rawValue: 3)
}
