import Foundation
import OTPFeed
import XCTest

@MainActor
final class CodeDetailViewModelTests: XCTestCase {
    func test_detailMenuItems_hasOneExpectedItem() {
        let sut = makeSUT()

        XCTAssertEqual(sut.detailMenuItems.count, 1)
    }

    func test_makeEditingViewModel_initialStateUsesData() {
        var code = uniqueStoredCode()
        code.code.data.accountName = "account name test"
        code.code.data.issuer = "issuer test"
        code.userDescription = "description test"
        let sut = makeSUT(code: code)

        let editing = sut.makeEditingViewModel()

        XCTAssertEqual(editing.initialDetail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.initialDetail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.initialDetail.description, "description test")
    }

    func test_makeEditingViewModel_editingStateUsesData() {
        var code = uniqueStoredCode()
        code.code.data.accountName = "account name test"
        code.code.data.issuer = "issuer test"
        code.userDescription = "description test"
        let sut = makeSUT(code: code)

        let editing = sut.makeEditingViewModel()

        XCTAssertEqual(editing.detail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.detail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.detail.description, "description test")
    }
}

extension CodeDetailViewModelTests {
    private func makeSUT(code: StoredOTPCode = uniqueStoredCode()) -> CodeDetailViewModel {
        CodeDetailViewModel(storedCode: code)
    }
}
