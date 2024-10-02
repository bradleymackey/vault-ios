import Foundation
import PackagePlugin

// swiftlint:disable no_direct_standard_out_logs

@main
struct FormatLintPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let formatLintContext = try makeFormatLintContext(context: context, arguments: arguments)

        let start = Date()
        // Lint before formatting so any formatting that results in lint errors is surfaced and we can address it.
        try formatLintContext.runSwiftLint()
        try formatLintContext.runSwiftFormat()
        let end = Date()
        let elapsed = end.timeIntervalSince(start)
        print("✅ in \(String(format: "%.2f", elapsed)) seconds")
    }

    enum MissingParameterError: Error {
        case sources
    }

    private func makeFormatLintContext(context: PluginContext, arguments: [String]) throws -> FormatLintContext {
        var argumentExtractor = ArgumentExtractor(arguments)
        guard let swiftSources = argumentExtractor.extractOption(named: "sources").first else {
            throw MissingParameterError.sources
        }
        let action: Action = if argumentExtractor.extractFlag(named: "lint") > 0 {
            .lint
        } else {
            .format
        }
        return try FormatLintContext(
            swiftlint: context.tool(named: "swiftlint"),
            swiftformat: context.tool(named: "swiftformat"),
            workDirectory: context.pluginWorkDirectoryURL,
            swiftSourcesDirectory: swiftSources,
            action: action
        )
    }
}

struct FormatLintContext {
    var swiftlint: PluginContext.Tool
    var swiftformat: PluginContext.Tool
    var workDirectory: URL
    var swiftSourcesDirectory: String
    var action: Action
}

extension FormatLintContext {
    func makeSwiftLintArgs() -> [String] {
        var swiftLintArguments = [String]()
        swiftLintArguments += ["--cache-path", workDirectory.appending(path: "swiftlint.cache").path()]
        swiftLintArguments += ["--quiet"]
        switch action {
        case .format:
            swiftLintArguments += ["--fix"]
        case .lint:
            swiftLintArguments += ["--strict"]
        }
        swiftLintArguments += [swiftSourcesDirectory]
        return swiftLintArguments
    }

    func runSwiftLint() throws {
        print("🔍 swiftlint: \(action.swiftLintVerb.lowercased())")
        try runProcess(
            url: swiftlint.url,
            arguments: makeSwiftLintArgs()
        )
    }
}

// MARK: - swiftformat

extension FormatLintContext {
    func makeSwiftFormatArgs() -> [String] {
        var swiftFormatArguments = [String]()
        swiftFormatArguments += ["--cache", workDirectory.appending(path: "swiftformat.cache").path()]
        swiftFormatArguments += ["--quiet"]
        if action == .lint {
            swiftFormatArguments += ["--lint"]
        }
        swiftFormatArguments += [swiftSourcesDirectory]
        return swiftFormatArguments
    }

    func runSwiftFormat() throws {
        print("🖌️ swiftformat: \(action.swiftFormatVerb.lowercased())")
        try runProcess(
            url: swiftformat.url,
            arguments: makeSwiftFormatArgs()
        )
    }
}

// MARK: - Plugin

enum Action {
    case format
    case lint

    var swiftFormatVerb: String {
        switch self {
        case .format: "Formatting"
        case .lint: "Checking"
        }
    }

    var swiftLintVerb: String {
        switch self {
        case .format: "Fixing"
        case .lint: "Linting"
        }
    }
}

enum CommandError: Error {
    case commandFailure
    case unknownError(exitCode: Int32)
}

func runProcess(url: URL, arguments: [String]) throws {
    let process = Process()
    process.executableURL = url
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()

    switch process.terminationStatus {
    case 0: break
    case 1:
        print("🚨 Issues found")
        throw CommandError.commandFailure
    default:
        print("💀 Command failure")
        throw CommandError.unknownError(exitCode: process.terminationStatus)
    }
}
