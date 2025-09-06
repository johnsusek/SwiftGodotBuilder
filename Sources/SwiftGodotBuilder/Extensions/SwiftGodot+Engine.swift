import SwiftGodot

public extension Engine {
  static func getSceneTree() -> SceneTree? {
    Engine.getMainLoop() as? SceneTree
  }
}
