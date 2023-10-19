// MIT License
//
// Copyright (c) 2012 Airbnb
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Created by Cal Stephens on 9/25/23.
// Copyright © 2023 Airbnb Inc. All rights reserved.

import Foundation

/// A single command line invocation
struct Command {
    // MARK: Internal

    /// This property can be overridden to provide a mock implementation in unit tests.
    static var runCommand: (Command) throws -> Int32 = { try $0.executeShellCommand() }

    let log: Bool
    let launchPath: String
    let arguments: [String]

    /// Runs this command using the implementation of `Command.runCommand`
    ///  - By default, synchronously runs this command and returns its exit code
    func run() throws -> Int32 {
        try Command.runCommand(self)
    }

    // MARK: Private

    /// Synchronously runs this command and returns its exit code
    private func executeShellCommand() throws -> Int32 {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments

        if log {
            log(process.shellCommand)
        }

        try process.run()
        process.waitUntilExit()

        if log {
            let commandName = process.launchPath?.components(separatedBy: "/").last ?? "unknown"
            log("\(commandName) command completed with exit code \(process.terminationStatus)")
        }

        return process.terminationStatus
    }

    private func log(_ string: String) {
        // swiftlint:disable:next no_direct_standard_out_logs
        print("[AibnbSwiftFormatTool]", string)
    }
}
