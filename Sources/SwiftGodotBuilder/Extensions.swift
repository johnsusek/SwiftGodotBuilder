import SwiftGodot

public extension RectangleShape2D {
  /// Convenience initializer.
  convenience init(x: Float, y: Float) {
    self.init()
    size = Vector2(x: x, y: y)
  }
}

public extension Vector2 {
  /// Convenience initializer.
  init(_ x: Float, _ y: Float) {
    self.init(x: x, y: y)
  }
}

public extension Node {
  /// Typed group lookup; returns [] if no tree or group is empty.
  func nodes<T: Node>(inGroup name: StringName, as _: T.Type = T.self) -> [T] {
    guard let arr = getTree()?.getNodesInGroup(name) else { return [] }
    return arr.compactMap { $0 as? T }
  }
}
