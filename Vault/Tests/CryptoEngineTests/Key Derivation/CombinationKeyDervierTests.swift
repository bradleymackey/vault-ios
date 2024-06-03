import Foundation
import TestHelpers
import XCTest
@testable import CryptoEngine

final class CombinationKeyDeriverTests: XCTestCase {
    func test_key_throwsErrorIfNoKeyDerivers() {
        let sut = CombinationKeyDeriver(derivers: [])

        XCTAssertThrowsError(try sut.key(password: anyData(), salt: anyData()))
    }

    func test_key_returnsResultOfSingleKeyDeriver() throws {
        let expectedData = Data(hex: "ababdfdf1234")
        let deriver = KeyDeriverMock()
        deriver.keyHandler = { _, _ in
            expectedData
        }
        let sut = CombinationKeyDeriver(derivers: [deriver])

        let result = try sut.key(password: anyData(), salt: anyData())
        XCTAssertEqual(result, expectedData)
        XCTAssertEqual(deriver.keyCallCount, 1)
    }

    func test_key_returnsResultOfLastKeyDervier() throws {
        let deriver1 = mockKeyDeriver(returning: Data(hex: "0000"))
        let deriver2 = mockKeyDeriver(returning: Data(hex: "1111"))
        let deriver3 = mockKeyDeriver(returning: Data(hex: "2222"))
        let sut = CombinationKeyDeriver(derivers: [deriver1, deriver2, deriver3])

        let result = try sut.key(password: anyData(), salt: anyData())
        XCTAssertEqual(result, Data(hex: "2222"))
        XCTAssertEqual(deriver1.keyCallCount, 1)
        XCTAssertEqual(deriver2.keyCallCount, 1)
        XCTAssertEqual(deriver3.keyCallCount, 1)
    }

    func test_key_usesKeyFromPreviousDeriverInNextDeriver() throws {
        let deriver1 = mockKeyDeriver(returning: Data(hex: "0000"))
        let deriver2 = mockKeyDeriver(returning: Data(hex: "1111"))
        let deriver3 = mockKeyDeriver(returning: Data(hex: "2222"))
        let sut = CombinationKeyDeriver(derivers: [deriver1, deriver2, deriver3])

        let initialPassword = Data(hex: "deadbeef")
        _ = try sut.key(password: initialPassword, salt: anyData())
        XCTAssertEqual(deriver1.keyArgValues.first?.0, initialPassword)
        XCTAssertEqual(deriver2.keyArgValues.first?.0, Data(hex: "0000"))
        XCTAssertEqual(deriver3.keyArgValues.first?.0, Data(hex: "1111"))
    }

    func test_key_usesSameSaltForAllDerivers() throws {
        let deriver1 = mockKeyDeriver(returning: Data(hex: "0000"))
        let deriver2 = mockKeyDeriver(returning: Data(hex: "1111"))
        let deriver3 = mockKeyDeriver(returning: Data(hex: "2222"))
        let sut = CombinationKeyDeriver(derivers: [deriver1, deriver2, deriver3])

        let salt = Data(hex: "123456789aaaa")
        _ = try sut.key(password: anyData(), salt: salt)
        XCTAssertEqual(deriver1.keyArgValues.first?.1, salt)
        XCTAssertEqual(deriver2.keyArgValues.first?.1, salt)
        XCTAssertEqual(deriver3.keyArgValues.first?.1, salt)
    }

    func test_key_checksCancellationBetweenAlgs() async throws {
        let exp1 = expectation(description: "Wait for signal")
        let exp2 = expectation(description: "Wait for signal")
        let deriver1 = mockKeyDeriver(uniqueAlgorithmIdentifier: "alg1")
        let deriver2 = signalKeyDeriver {
            exp1.fulfill()
        }
        let deriver3 = signalKeyDeriver {
            self.wait(for: [exp2])
        }
        let deriver4 = mockKeyDeriver(uniqueAlgorithmIdentifier: "alg3")

        let sut = CombinationKeyDeriver(derivers: [deriver1, deriver2, deriver3, deriver4])

        let exp3 = expectation(description: "Wait for task")
        let task = Task {
            defer { exp3.fulfill() }
            do {
                _ = try sut.key(password: Data(), salt: Data())
                XCTFail("Expected cancellation")
            } catch {
                XCTAssertTrue(error is CancellationError)
            }
        }

        // Wait for the second deriver to get hit. This will give us the opportunity to make sure we can
        // actually cancel it before the test code ends.
        await fulfillment(of: [exp1])

        // Cancel the alg.
        task.cancel()

        // Now, fire deriver3, which ensures that the sut keeps running and we hit the cancellation check.
        exp2.fulfill()

        // Final wait for task to complete, so we're sure the expectations run
        await fulfillment(of: [exp3])
    }

    func test_uniqueAlgorithmIdentifier_matchesParametersOfPassedAlgorithms() {
        let deriver1 = mockKeyDeriver(uniqueAlgorithmIdentifier: "alg1")
        let deriver2 = mockKeyDeriver(uniqueAlgorithmIdentifier: "alg2")
        let deriver3 = mockKeyDeriver(uniqueAlgorithmIdentifier: "alg3")

        let sut = CombinationKeyDeriver(derivers: [deriver1, deriver2, deriver3])

        XCTAssertEqual(sut.uniqueAlgorithmIdentifier, "COMBINATION<alg1|alg2|alg3>")
    }
}

// MARK: - Helpers

extension CombinationKeyDeriverTests {
    private func mockKeyDeriver(returning: Data) -> KeyDeriverMock {
        let deriver1 = KeyDeriverMock()
        deriver1.keyHandler = { _, _ in
            returning
        }
        return deriver1
    }

    private func mockKeyDeriver(uniqueAlgorithmIdentifier: String) -> KeyDeriverMock {
        let deriver1 = KeyDeriverMock()
        deriver1.uniqueAlgorithmIdentifier = uniqueAlgorithmIdentifier
        deriver1.keyHandler = { _, _ in
            Data()
        }
        return deriver1
    }

    private func signalKeyDeriver(signal: @escaping () -> Void) -> KeyDeriverMock {
        let deriver1 = KeyDeriverMock()
        deriver1.keyHandler = { _, _ in
            signal()
            return Data()
        }
        return deriver1
    }
}
