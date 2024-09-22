import Foundation
import PackagePlugin

@main
struct FormatLintPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let swiftlint = try context.tool(named: "swiftlint")
        let swiftformat = try context.tool(named: "swiftformat")

        var argumentExtractor = ArgumentExtractor(arguments)
        let shouldLint = argumentExtractor.extractFlag(named: "lint") > 0
        guard let swiftSources = argumentExtractor.extractOption(named: "sources").first else {
            fatalError("Missing parameter: --sources")
        }

        var swiftFormatArguments = [String]()
        swiftFormatArguments += ["--cache", context.pluginWorkDirectoryURL.appending(path: "swiftformat.cache").path()]
        swiftFormatArguments += ["--quiet"]
        if shouldLint {
            swiftFormatArguments += ["--lint"]
        }
        swiftFormatArguments += [swiftSources]

        var swiftLintArguments = [String]()
        swiftLintArguments += ["--cache-path", context.pluginWorkDirectoryURL.appending(path: "swiftlint.cache").path()]
        swiftLintArguments += ["--quiet"]
        if !shouldLint {
            swiftLintArguments += ["--fix"]
        }
        swiftLintArguments += [swiftSources]

        try runProcess(url: swiftformat.url, arguments: swiftFormatArguments)
        try runProcess(url: swiftlint.url, arguments: swiftLintArguments)
    }

    private func runProcess(url: URL, arguments: [String]) throws {
        let process = Process()
        process.executableURL = url
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()

        switch process.terminationStatus {
        case 0: break
        case 1: throw CommandError.commandFailure
        default: throw CommandError.unknownError(exitCode: process.terminationStatus)
        }
    }
}

enum CommandError: Error {
    case commandFailure
    case unknownError(exitCode: Int32)
}
