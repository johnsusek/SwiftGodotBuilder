import SwiftUI
import SwiftGodot
import SwiftGodotKit
import SwiftGodotBuilder

@main
struct SwiftGodotBuilderExampleApp: App {
  @State var app = GodotApp(packFile: "game.pck")

  var body: some Scene {
    Window("Swift Godot Builder - Example", id: "main") {
      GodotAppView()
        .environment(\.godotApp, app)
        .task {
          await bootstrap()
        }
    }
  }

  func bootstrap() async {
    guard let sceneTree = await waitForSceneTree(), let root = sceneTree.root else {
      print("Godot instance: timeout")
      return
    }
  }

  func waitForSceneTree(_ tries: Int = 300, intervalNS: UInt64 = 200_000_000) async -> SceneTree? {
    for _ in 0..<tries {
      if app.instance != nil, let t = Engine.getMainLoop() as? SceneTree { return t }
      try? await Task.sleep(nanoseconds: intervalNS)
    }
    return nil
  }

}
