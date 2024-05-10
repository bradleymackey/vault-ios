import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class FieldValidatedTests {
    func test_wrappedValue_setsBasedOnValue() {
        @FieldValidated(validationLogic: .alwaysValid) var sut = "Hello"
        XCTAssertEqual(sut, "Hello")

        sut = "Hello, world"
        XCTAssertEqual(sut, "Hello, world")
    }

    func test_projectedValue_getsCorrectValidationState() {
        let validOnFoo = FieldValidationLogic<String>(validate: { $0 == "foo" ? .valid : .invalid })
        @FieldValidated(validationLogic: validOnFoo) var sut = "Hello"
        XCTAssertFalse($sut.isValid)

        sut = "foo"
        XCTAssertTrue($sut.isValid)

        sut = "bar"
        XCTAssertFalse($sut.isValid)
    }

    func test_isEqual_ifContentIsEqual() {
        @FieldValidated(validationLogic: .alwaysValid) var sut1 = "Hello"
        @FieldValidated(validationLogic: .alwaysInvalid) var sut2 = "Hello"

        XCTAssertEqual(sut1, sut2)

        @FieldValidated(validationLogic: .alwaysValid) var sut3 = "Hello"
        @FieldValidated(validationLogic: .alwaysInvalid) var sut4 = "World"

        XCTAssertNotEqual(sut3, sut4)
    }

    func test_alwaysValid_isValid() {
        @FieldValidated(validationLogic: .alwaysValid) var sut = "Hello"

        XCTAssertTrue($sut.isValid)
        XCTAssertFalse($sut.isError)
    }

    func test_alwaysInvalid_isInvalid() {
        @FieldValidated(validationLogic: .alwaysInvalid) var sut = "Hello"

        XCTAssertFalse($sut.isValid)
        XCTAssertFalse($sut.isError)
    }

    func test_alwaysError_isError() {
        @FieldValidated(validationLogic: .alwaysError) var sut = "Hello"

        XCTAssertFalse($sut.isValid)
        XCTAssertTrue($sut.isError)
    }

    func test_stringRequiringContent_invalidForEmpty() {
        @FieldValidated(validationLogic: .stringRequiringContent) var sut = ""
        XCTAssertFalse($sut.isValid)
    }

    func test_stringRequiringContent_invalidForBlank() {
        @FieldValidated(validationLogic: .stringRequiringContent) var sut = "  \n\n\t"
        XCTAssertFalse($sut.isValid)
    }

    func test_stringRequiringContent_validForSomeContent() {
        @FieldValidated(validationLogic: .stringRequiringContent) var sut = "  Hello  "
        XCTAssertTrue($sut.isValid)
        sut = "nice"
        XCTAssertTrue($sut.isValid)
    }
}
