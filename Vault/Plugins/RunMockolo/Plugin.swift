import PackagePlugin

@main
struct MockoloPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let generatedSource = context.pluginWorkDirectoryURL.appending(path: "GeneratedMocks.swift")
        let packageRoot = context.package.directoryURL

        return try [
            .prebuildCommand(
                displayName: "Run mockolo",
                executable: context.tool(named: "mockolo").url,
                arguments: [
                    "-s", packageRoot.appending(path: "Sources").appending(path: target.name).path(),
                    "-d", generatedSource.path(),
                    "--mock-final",
                    "--enable-args-history",
                ],
                outputFilesDirectory: context.pluginWorkDirectoryURL
            ),
        ]
    }
}
