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
          await bootstrap()
        }
    }
  }

  func bootstrap() async {
    guard let sceneTree = await waitForSceneTree(), let root = sceneTree.root else {
      print("Godot instance: timeout")
      return
    }

    register(type: Player.self)
    register(type: Ball.self)
    register(type: Paddle.self)

    actions.install()

    let uiViewNode = PongView().makeNode()
    root.addChild(node: uiViewNode)
  }

  func waitForSceneTree() async -> SceneTree? {
    for _ in 0 ..< 300 {
      if app.instance != nil, let t = Engine.getMainLoop() as? SceneTree { return t }
      try? await Task.sleep(nanoseconds: 200_000_000)
    }
    return nil
  }
}
