import PackagePlugin

/**
  Generates GView aliases (e.g. Node2D$) for Godot Nodes at build time from a Godot engine `extension_api.json`

  ## Overview
  This SwiftPM ``BuildToolPlugin`` runs during the build of any Swift target in
  the package. It invokes the `NodeApiGen` tool with the package-local
  `extension_api.json` as input and writes a single Swift file,
  `GeneratedGNodeAliases.swift`, into the plugin's work directory. That file is
  then compiled as part of the target via SwiftPM's build tool outputs.

  ### Inputs
  - `extension_api.json` located at the package root (`context.package.directory`).

  ### Outputs
  - `GeneratedGNodeAliases.swift` written to `context.pluginWorkDirectory`.
 **/
@main
struct GenNodeApi: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
    guard target is SwiftSourceModuleTarget else { return [] }
    let tool = try context.tool(named: "NodeApiGen").path
    let api = context.package.directory.appending("data/extension_api_v4.4.json")
    let outA = context.pluginWorkDirectory.appending("GeneratedGNodeAliases.swift")
    return [.buildCommand(
      displayName: "Generate aliases from extension_api.json",
      executable: tool,
      arguments: [api.string, outA.string],
      outputFiles: [outA]
    )]
  }
}
