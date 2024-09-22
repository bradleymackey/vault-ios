import Foundation
import PackagePlugin

@main
struct FormatLintPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let swiftlint = try context.tool(named: "swiftlint")
        let swiftformat = try context.tool(named: "swiftformat")

        var argumentExtractor = ArgumentExtractor(arguments)
        let shouldLint = argumentExtractor.extractFlag(named: "lint") > 0
        guard let lintConfig = argumentExtractor.extractOption(named: "swiftlint-config").first else {
            fatalError("Missing parameter: --swiftlint-config")
        }
        guard let formatConfig = argumentExtractor.extractOption(named: "swiftformat-config").first else {
            fatalError("Missing parameter: --swiftformat-config")
        }
        guard let swiftSources = argumentExtractor.extractOption(named: "sources").first else {
            fatalError("Missing parameter: --sources")
        }

        var swiftFormatArguments = [String]()
        swiftFormatArguments += [swiftSources]
        if shouldLint {
            swiftFormatArguments += ["--lint"]
        }
        swiftFormatArguments += ["--quiet"]

        let formatProcess = Process()
        formatProcess.executableURL = swiftformat.url
        formatProcess.arguments = swiftFormatArguments
        try formatProcess.run()
        formatProcess.waitUntilExit()

        switch formatProcess.terminationStatus {
        case 0: break
        case 1: throw CommandError.commandFailure
        default: throw CommandError.unknownError(exitCode: formatProcess.terminationStatus)
        }

        var swiftLintArguments = [String]()
        swiftLintArguments += ["--quiet"]
        if !shouldLint {
            swiftLintArguments += ["--fix"]
        }

        let lintProcess = Process()
        lintProcess.executableURL = swiftlint.url
        lintProcess.arguments = swiftLintArguments
        try lintProcess.run()
        lintProcess.waitUntilExit()

        switch formatProcess.terminationStatus {
        case 0: break
        case 1: throw CommandError.commandFailure
        default: throw CommandError.unknownError(exitCode: lintProcess.terminationStatus)
        }
    }
}

enum CommandError: Error {
    case commandFailure
    case unknownError(exitCode: Int32)
}
