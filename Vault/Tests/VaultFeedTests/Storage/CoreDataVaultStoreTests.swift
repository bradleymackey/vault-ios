import CoreData
import VaultCore
import VaultFeed
import XCTest

final class CoreDataVaultStoreTests: XCTestCase {
    func test_retrieve_deliversEmptyOnEmptyStore() async throws {
        let sut = try makeSUT()

        let result = try await sut.retrieve()
        XCTAssertEqual(result, [])
    }

    func test_retrieve_hasNoSideEffectsOnEmptyStore() async throws {
        let sut = try makeSUT()

        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1, [])
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2, [])
    }

    func test_retrieve_deliversSingleCodeOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        let code = uniqueWritableVaultItem()
        try await sut.insert(item: code)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), [code.item.otpCode])
    }

    func test_retrieve_deliversMultipleCodesOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), codes.map(\.item.otpCode))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1.map(\.item.otpCode), codes.map(\.item.otpCode))
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2.map(\.item.otpCode), codes.map(\.item.otpCode))
    }

    func test_retrieve_deliversErrorOnRetrievalError() async throws {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = try makeSUT()

        await expectThrows(nsError: anyNSError()) {
            _ = try await sut.retrieve()
        }
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStoreAndEmptyQuery() async throws {
        let sut = try makeSUT()

        let result = try await sut.retrieve(matching: "")
        XCTAssertEqual(result, [])
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStore() async throws {
        let sut = try makeSUT()

        let result = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result, [])
    }

    func test_retrieveMatchingQuery_hasNoSideEffectsOnEmptyStore() async throws {
        let sut = try makeSUT()

        let result1 = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result1, [])
        let result2 = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result2, [])
    }

    func test_retrieveMatchingQuery_returnsEmptyForNoQueryMatches() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result, [])
    }

    func test_retrieveMatchingQuery_deliversSingleMatchOnMatchingQuery() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(userDescription: "yes"),
            writableSearchableOTPVaultItem(userDescription: "no"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
    }

    func test_retrieveMatchingQuery_hasNoSideEffectsOnSingleMatch() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(userDescription: "yes"),
            writableSearchableOTPVaultItem(userDescription: "no"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result1 = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result1.count, 1)
        XCTAssertEqual(result1.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
        let result2 = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result2.count, 1)
        XCTAssertEqual(result2.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
    }

    func test_retrieveMatchingQuery_deliversMultipleMatchesOnMatchingQuery() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableOTPVaultItem(userDescription: "no"),
            writableSearchableNoteVaultItem(userDescription: "yes"),
            writableSearchableOTPVaultItem(userDescription: "no"),
            writableSearchableOTPVaultItem(userDescription: "yess"),
            writableSearchableOTPVaultItem(userDescription: "yesss"),
            writableSearchableOTPVaultItem(userDescription: "no"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.map(\.metadata.userDescription), ["yes", "yess", "yesss"])
    }

    func test_retrieveMatchingQuery_deliversErrorOnRetrievalError() async throws {
        let stub = NSManagedObjectContext.alwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = try makeSUT()

        await expectThrows(nsError: anyNSError()) {
            _ = try await sut.retrieve(matching: "any")
        }
    }

    func test_retrieveMatchingQuery_matchesUserDescription() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(userDescription: "x"),
            writableSearchableNoteVaultItem(userDescription: "a"),
            writableSearchableOTPVaultItem(userDescription: "c"),
            writableSearchableOTPVaultItem(userDescription: "b"),
            writableSearchableOTPVaultItem(userDescription: "----a----"),
            writableSearchableOTPVaultItem(userDescription: "----A----"),
            writableSearchableOTPVaultItem(userDescription: "x"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.map(\.metadata.userDescription), ["a", "----a----", "----A----"])
    }

    func test_retrieveMatchingQuery_matchesOTPAccountName() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(accountName: "a"),
            writableSearchableOTPVaultItem(accountName: "x"),
            writableSearchableOTPVaultItem(accountName: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.compactMap(\.item.otpCode?.data.accountName), ["a", "----A----"])
    }

    func test_retrieveMatchingQuery_matchesOTPIssuer() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(issuerName: "a"),
            writableSearchableOTPVaultItem(issuerName: "x"),
            writableSearchableOTPVaultItem(issuerName: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.compactMap(\.item.otpCode?.data.issuer), ["a", "----A----"])
    }

    func test_retrieveMatchingQuery_matchesNoteDetailsTitle() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableNoteVaultItem(title: "a"),
            writableSearchableNoteVaultItem(title: "x"),
            writableSearchableNoteVaultItem(title: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.compactMap(\.item.secureNote?.title), ["a", "----A----"])
    }

    func test_retrieveMatchingQuery_matchesNoteDetailsContents() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableNoteVaultItem(contents: "a"),
            writableSearchableNoteVaultItem(contents: "x"),
            writableSearchableNoteVaultItem(contents: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.compactMap(\.item.secureNote?.contents), ["a", "----A----"])
    }

    func test_retrieveMatchingQuery_combinesResultsFromDifferentFields() async throws {
        let sut = try makeSUT()

        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(userDescription: "a"),
            writableSearchableNoteVaultItem(title: "aa"),
            writableSearchableNoteVaultItem(contents: "aaa"),
            writableSearchableOTPVaultItem(userDescription: "aaaa"),
            writableSearchableOTPVaultItem(accountName: "aaaaa"),
            writableSearchableOTPVaultItem(issuerName: "aaaaaa"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.map(\.asWritable), codes, "All items should be matched on the specified fields")
    }

    func test_insert_deliversNoErrorOnEmptyStore() async throws {
        let sut = try makeSUT()

        try await sut.insert(item: uniqueWritableVaultItem())
    }

    func test_insert_deliversNoErrorOnNonEmptyStore() async throws {
        let sut = try makeSUT()

        try await sut.insert(item: uniqueWritableVaultItem())
        try await sut.insert(item: uniqueWritableVaultItem())
    }

    func test_insert_doesNotOverrideExactSameEntryAsUsesNewIDToUnique() async throws {
        let sut = try makeSUT()
        let code = uniqueWritableVaultItem()

        try await sut.insert(item: code)
        try await sut.insert(item: code)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), [code.item.otpCode, code.item.otpCode])
    }

    func test_insert_returnsUniqueCodeIDAfterSuccessfulInsert() async throws {
        let sut = try makeSUT()
        let code = uniqueWritableVaultItem()

        var ids = [UUID]()
        for _ in 0 ..< 5 {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.id), ids)
    }

    func test_insert_deliversErrorOnInsertionError() async throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()

        let sut = try makeSUT()
        await expectThrows(nsError: anyNSError()) {
            try await sut.insert(item: uniqueWritableVaultItem())
        }
    }

    func test_insert_hasNoSideEffectsOnInsertionError() async throws {
        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()

        let sut = try makeSUT()
        _ = try? await sut.insert(item: uniqueWritableVaultItem())

        let results = try await sut.retrieve()
        XCTAssertEqual(results, [])
    }

    func test_deleteByID_hasNoEffectOnEmptyStore() async throws {
        let sut = try makeSUT()

        try await sut.delete(id: UUID())

        let results = try await sut.retrieve()
        XCTAssertEqual(results, [])
    }

    func test_deleteByID_deletesSingleEntryMatchingID() async throws {
        let sut = try makeSUT()
        let code = uniqueWritableVaultItem()

        let id = try await sut.insert(item: code)

        try await sut.delete(id: id)

        let results = try await sut.retrieve()
        XCTAssertEqual(results, [])
    }

    func test_deleteByID_hasNoEffectOnNoMatchingCode() async throws {
        let sut = try makeSUT()

        let otherCodes = [uniqueWritableVaultItem(), uniqueWritableVaultItem(), uniqueWritableVaultItem()]
        for code in otherCodes {
            try await sut.insert(item: code)
        }

        try await sut.delete(id: UUID())

        let results = try await sut.retrieve()
        XCTAssertEqual(results.map(\.item.otpCode), otherCodes.map(\.item.otpCode))
    }

    func test_deleteByID_deliversErrorOnDeletionError() async throws {
        let sut = try makeSUT()
        let id = try await sut.insert(item: uniqueWritableVaultItem())

        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()

        await expectThrows(nsError: anyNSError(), operation: {
            try await sut.delete(id: id)
        })
    }

    func test_updateByID_deliversErrorIfCodeDoesNotAlreadyExist() async throws {
        let sut = try makeSUT()

        do {
            try await sut.update(id: UUID(), item: uniqueWritableVaultItem())
            XCTFail("Expected to throw error")
        } catch {
            // ignore
        }
    }

    func test_updateByID_hasNoEffectOnEmptyStorageIfCodeDoesNotAlreadyExist() async throws {
        let sut = try makeSUT()

        try? await sut.update(id: UUID(), item: uniqueWritableVaultItem())

        let result = try await sut.retrieve()
        XCTAssertEqual(result, [])
    }

    func test_updateByID_hasNoEffectOnNonEmptyStorageIfCodeDoesNotAlreadyExist() async throws {
        let sut = try makeSUT()
        let codes = [uniqueWritableVaultItem(), uniqueWritableVaultItem(), uniqueWritableVaultItem()]
        for code in codes {
            try await sut.insert(item: code)
        }

        try? await sut.update(id: UUID(), item: uniqueWritableVaultItem())

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), codes.map(\.item.otpCode))
    }

    func test_updateByID_updatesDataForValidCode() async throws {
        let sut = try makeSUT()
        let initialCode = uniqueWritableVaultItem()
        let id = try await sut.insert(item: initialCode)

        let newCode = uniqueWritableVaultItem()
        try await sut.update(id: id, item: newCode)

        let result = try await sut.retrieve()
        XCTAssertNotEqual(result.map(\.item.otpCode), [initialCode.item.otpCode], "Should be different from old code.")
        XCTAssertEqual(result.map(\.item.otpCode), [newCode.item.otpCode], "Should be the same as the new code.")
    }

    func test_updateByID_hasNoSideEffectsOnOtherCodes() async throws {
        let sut = try makeSUT()
        let initialCodes = [uniqueWritableVaultItem(), uniqueWritableVaultItem(), uniqueWritableVaultItem()]
        for code in initialCodes {
            try await sut.insert(item: code)
        }

        let id = try await sut.insert(item: uniqueWritableVaultItem())

        let newCode = uniqueWritableVaultItem()
        try await sut.update(id: id, item: newCode)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), initialCodes.map(\.item.otpCode) + [newCode.item.otpCode])
    }

    func test_updateByID_deliversErrorOnUpdateError() async throws {
        let sut = try makeSUT()

        let id = try await sut.insert(item: uniqueWritableVaultItem())

        let stub = NSManagedObjectContext.alwaysFailingSaveStub()
        stub.startIntercepting()

        await expectThrows(nsError: anyNSError()) {
            try await sut.update(id: id, item: uniqueWritableVaultItem())
        }
    }
}

// MARK: - Helpers

extension CoreDataVaultStoreTests {
    private func makeSUT(file _: StaticString = #filePath, line _: UInt = #line) throws -> some VaultStore {
        let sut = try CoreDataVaultStore(storeURL: inMemoryStoreURL())
        return sut
    }

    private func expectThrows(
        nsError expectedError: NSError,
        operation: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await operation()
            XCTFail("Expected to throw \(expectedError) but operation completed successfully", file: file, line: line)
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, expectedError.domain, file: file, line: line)
            XCTAssertEqual(nsError.code, expectedError.code, file: file, line: line)
        }
    }

    private func inMemoryStoreURL() -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
}
