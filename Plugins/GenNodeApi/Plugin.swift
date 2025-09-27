// Sources/GenNodeApi/GenNodeApi.swift
#if canImport(PackagePlugin)
  import Foundation
  import PackagePlugin

  @main
  struct GenNodeApi: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
      guard let swiftTarget = target as? SwiftSourceModuleTarget else { return [] }

      let tool = try context.tool(named: "NodeApiGen")

      // Resolve extension_api.json; override with SWIFTGODOT_EXTENSION_API if you like.
      let apiPath = resolveAPIPath(context: context, target: swiftTarget)

      let outDir = context.pluginWorkDirectory.appending("nodeapi")
      let outFile = outDir.appending("GeneratedGNodeAliases.swift")

      return [.buildCommand(
        displayName: "NodeApiGen -> \(outFile.lastComponent)",
        executable: tool.path,
        arguments: [apiPath.string, outFile.string],
        environment: [:],
        inputFiles: [apiPath, tool.path], // rerun if API or generator changes
        outputFiles: [outFile] // incremental cache key
      )]
    }

    private func resolveAPIPath(context: PluginContext, target: SwiftSourceModuleTarget) -> Path {
      if let env = ProcessInfo.processInfo.environment["SWIFTGODOT_EXTENSION_API"], !env.isEmpty { return Path(env) }
      let root = context.package.directory
      let local = root.appending("extension_api.json")
      if FileManager.default.fileExists(atPath: local.string) { return local }
      return target.directory.appending("Resources/extension_api.json")
    }
  }
#endif
