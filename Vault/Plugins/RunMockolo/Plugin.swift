import PackagePlugin

@main
struct MockoloPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let generatedSourcePath = context.pluginWorkDirectory.appending("GeneratedMocks.swift")
        let packageRoot = context.package.directory

        return try [
            .prebuildCommand(
                displayName: "Run mockolo",
                executable: context.tool(named: "mockolo").path,
                arguments: [
                    "-s", packageRoot.appending("Sources", target.name).string,
                    "-d", generatedSourcePath,
                    "--mock-final",
                    "--enable-args-history",
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            ),
        ]
    }
}
