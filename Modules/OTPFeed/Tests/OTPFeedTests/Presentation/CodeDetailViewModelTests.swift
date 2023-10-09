import Foundation
import OTPFeed
import XCTest

@MainActor
final class CodeDetailViewModelTests: XCTestCase {
    func test_detailMenuItems_hasOneExpectedItem() {
        let sut = makeSUT()

        XCTAssertEqual(sut.detailMenuItems.count, 1)
    }

    func test_editingModel_initialStateUsesData() {
        var code = uniqueStoredCode()
        code.code.data.accountName = "account name test"
        code.code.data.issuer = "issuer test"
        code.userDescription = "description test"
        let sut = makeSUT(code: code)

        let editing = sut.editingModel

        XCTAssertEqual(editing.initialDetail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.initialDetail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.initialDetail.description, "description test")
    }

    func test_editingModel_editingStateUsesData() {
        var code = uniqueStoredCode()
        code.code.data.accountName = "account name test"
        code.code.data.issuer = "issuer test"
        code.userDescription = "description test"
        let sut = makeSUT(code: code)

        let editing = sut.editingModel

        XCTAssertEqual(editing.detail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.detail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.detail.description, "description test")
    }
}

extension CodeDetailViewModelTests {
    private func makeSUT(
        code: StoredOTPCode = uniqueStoredCode(),
        editor: CodeDetailEditorMock = CodeDetailEditorMock(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CodeDetailViewModel {
        let sut = CodeDetailViewModel(storedCode: code, editor: editor)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(editor, file: file, line: line)
        return sut
    }

    private class CodeDetailEditorMock: CodeDetailEditor {
        var updateCodeCalled: (StoredOTPCode, CodeDetailEdits) -> Void = { _, _ in }
        func update(code: StoredOTPCode, edits: CodeDetailEdits) async throws {
            updateCodeCalled(code, edits)
        }

        var deleteCodeCalled: (UUID) -> Void = { _ in }
        func deleteCode(id: UUID) async throws {
            deleteCodeCalled(id)
        }
    }
}
