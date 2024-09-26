import Foundation
import Testing
@testable import VaultFeed

struct OTPCodeScanningHandlerTests {
    let sut = OTPCodeScanningHandler()

    @Test(arguments: ["", "invalid", "invalid://totp/issuer"])
    func decode_invalidDataThrowsError(string: String) {
        #expect(throws: (any Error).self) {
            try sut.decode(data: string)
        }
    }

    @Test
    func decode_successCompletesWithExpectedCode() throws {
        let result = try sut.decode(data: "otpauth://totp/issuer?secret=AA&algorithm=SHA256&digits=7&period=32")

        switch result {
        case let .completedScanning(code):
            #expect(code.data.secret.base32EncodedString == "AA======")
            #expect(code.data.algorithm == .sha256)
            #expect(code.type.kind == .totp)
            #expect(code.data.digits == .init(value: 7))
        case .continueScanning:
            Issue.record("Expected completedScanning")
        }
    }
}
