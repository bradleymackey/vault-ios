import Foundation
import PackagePlugin

// swiftlint:disable no_direct_standard_out_logs

@main
struct FormatLintPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let swiftlint = try context.tool(named: "swiftlint")
        let swiftformat = try context.tool(named: "swiftformat")

        var argumentExtractor = ArgumentExtractor(arguments)
        let action: Action = if argumentExtractor.extractFlag(named: "lint") > 0 {
            .lint
        } else {
            .format
        }
        guard let swiftSources = argumentExtractor.extractOption(named: "sources").first else {
            fatalError("Missing parameter: --sources")
        }

        var swiftFormatArguments = [String]()
        swiftFormatArguments += ["--cache", context.pluginWorkDirectoryURL.appending(path: "swiftformat.cache").path()]
        swiftFormatArguments += ["--quiet"]
        if action == .lint {
            swiftFormatArguments += ["--lint"]
        }
        swiftFormatArguments += [swiftSources]

        var swiftLintArguments = [String]()
        swiftLintArguments += ["--cache-path", context.pluginWorkDirectoryURL.appending(path: "swiftlint.cache").path()]
        swiftLintArguments += ["--quiet"]
        switch action {
        case .format:
            swiftLintArguments += ["--fix"]
        case .lint:
            swiftLintArguments += ["--strict"]
        }
        swiftLintArguments += [swiftSources]

        let start = Date()
        print("🖌️ swiftformat: \(action.swiftFormatVerb.lowercased())")
        try runProcess(url: swiftformat.url, arguments: swiftFormatArguments)
        print("🔍 swiftlint: \(action.swiftLintVerb.lowercased())")
        try runProcess(url: swiftlint.url, arguments: swiftLintArguments)

        let end = Date()
        let elapsed = end.timeIntervalSince(start)
        print("✅ in \(String(format: "%.2f", elapsed)) seconds")
    }

    private func runProcess(url: URL, arguments: [String]) throws {
        let process = Process()
        process.executableURL = url
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()

        switch process.terminationStatus {
        case 0: break
        case 1:
            print("💀 Command failure")
            throw CommandError.commandFailure
        default:
            print("💀 Other failure")
            throw CommandError.unknownError(exitCode: process.terminationStatus)
        }
    }
}

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
