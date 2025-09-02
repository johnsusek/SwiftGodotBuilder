import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotKit
import SwiftUI

@main
struct SwiftGodotBuilderExampleApp: App {
  @State var app = GodotApp(packFile: "game.pck")

  var body: some Scene {
    Window("Swift Godot Builder - Example", id: "main") {
      GodotAppView()
        .environment(\.godotApp, app)
        .task {
          await startup()
        }
    }
  }

  func startup() async {
    await pollForAppInstance()
    let sceneTree = await pollForSceneTree()

    let view = PongView()
    let node = view.makeNode()

    sceneTree.root?.addChild(node: node)
  }

  func pollForAppInstance() async {
    for _ in 0 ..< 300 {
      if app.instance != nil { return }
      try? await Task.sleep(nanoseconds: 200_000_000)
    }

    fatalError("No SwiftGodotKit app instance - cannot continue!")
  }
}

private func pollForSceneTree() async -> SceneTree {
  for _ in 0 ..< 300 {
    if let t = Engine.getMainLoop() as? SceneTree { return t }
    try? await Task.sleep(nanoseconds: 200_000_000)
  }
  fatalError("No scene tree or scene root - cannot continue!")
}
