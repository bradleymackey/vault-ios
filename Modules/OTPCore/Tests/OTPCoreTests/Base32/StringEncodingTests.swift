//
//  StringExtensionTests.swift
//  Base32
//
//  Created by 野村 憲男 on 2/7/15.
//
//  Copyright (c) 2015 Norio Nomura
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import XCTest
@testable import OTPCore

final class StringExtensionTests: XCTestCase {
    func test_dataUsingUTF8StringEncoding() throws {
        let string = "0112233445566778899AABBCCDDEEFFaabbccddeefff"
        let expected = try XCTUnwrap(string.data(using: .utf8, allowLossyConversion: false))
        XCTAssertEqual(string.dataUsingUTF8StringEncoding, expected)
    }

    func test_dataUsingUTF8StringEncoding_empty() throws {
        let emptyString = ""
        let expected = try XCTUnwrap(emptyString.data(using: .utf8, allowLossyConversion: false))

        XCTAssertEqual(emptyString.dataUsingUTF8StringEncoding, expected)
    }
}
