import SwiftGodot
import SwiftGodotBuilder

func startup() {
  guard let sceneTree = Engine.getSceneTree() else { return }

//    let view = PongView()
//    let view = BreakoutView()
//    let view = SpaceInvadersView()
//    let view = HUDView()
//    let view = AsepriteView()
//    let view = PlaygroundView()
  let view = DinoGameView()

  let node = view.toNode()

  sceneTree.root?.addChild(node: node)
}

@_cdecl("swift_entry_point")
public func swift_entry_point(interfacePtr: OpaquePointer?, libraryPtr: OpaquePointer?, extensionPtr: OpaquePointer?) -> UInt8 {
  guard let interfacePtr, let libraryPtr, let extensionPtr else {
    return 0
  }

  initializeSwiftModule(interfacePtr, libraryPtr, extensionPtr, initHook: { if $0 == .scene { startup() } }, deInitHook: { _ in })

  return 1
}
