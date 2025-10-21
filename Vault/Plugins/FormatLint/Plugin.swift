import Foundation
import PackagePlugin

// swiftlint:disable no_direct_standard_out_logs

@main
struct FormatLintPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let formatLintContext = try makeFormatLintContext(context: context, arguments: arguments)

        let start = Date()
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
            swiftformat: context.tool(named: "swiftformat"),
            workDirectory: context.pluginWorkDirectoryURL,
            swiftSourcesDirectory: swiftSources,
            action: action
        )
    }
}

struct FormatLintContext {
    var swiftformat: PluginContext.Tool
    var workDirectory: URL
    var swiftSourcesDirectory: String
    var action: Action
}

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
            arguments: makeSwiftFormatArgs(),
            exitCodeHandler: swiftFormatExitCodeHandler(code:)
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
}

enum CommandError: Error {
    case exitWithError
    case unknownError(exitCode: Int32)
}

func runProcess(url: URL, arguments: [String], exitCodeHandler: (Int32) throws -> Void) throws {
    let process = Process()
    process.executableURL = url
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()

    try exitCodeHandler(process.terminationStatus)
}

func swiftFormatExitCodeHandler(code: Int32) throws {
    switch code {
    case 0:
        print("☑️ swiftformat done")
    case 1:
        print("❌ swiftformat linting failure")
        throw CommandError.exitWithError
    case 70:
        print("❌ swiftformat command failure")
        throw CommandError.exitWithError
    default:
        print("❌ swiftformat unknown failure")
        throw CommandError.unknownError(exitCode: code)
    }
}
