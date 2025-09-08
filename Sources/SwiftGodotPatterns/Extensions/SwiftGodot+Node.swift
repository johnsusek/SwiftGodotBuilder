import SwiftGodot

/// Convenience extensions for Godot types.

public extension Node {
  /// Typed group lookup; returns [] if no tree or group is empty.
  func nodes<T: Node>(inGroup name: StringName, as _: T.Type = T.self) -> [T] {
    guard let arr = getTree()?.getNodesInGroup(name) else { return [] }
    return arr.compactMap { $0 as? T }
  }

  var visibleSize: Vector2 { getViewport()?.getVisibleRect().size ?? Vector2(0, 0) }

  var visibleCenter: Vector2 { let s = visibleSize; return Vector2(x: s.x * 0.5, y: s.y * 0.5) }

  /// Node lookup by string path; returns nil if not found.
  func getNode(_ path: String) -> Node? { getNode(path: NodePath(path)) }

  /// Typed node lookup by string path; returns nil if not found or wrong type.
  ///
  /// Example:
  ///
  /// ```swift
  /// let box: ColorRect = getNode("Box")
  /// ```
  ///
  /// Replaces:
  ///
  /// ```swift
  /// let box = self.getNode(path: NodePath("Box")) as? ColorRect
  /// ```
  func getNode<T: Node>(_ path: String) -> T? { getNode(path: NodePath(path)) as? T }

  /// Get all children of a specific type.
  ///
  /// Example:
  /// ```swift
  /// let sprites: [Sprite2D] = getChildren()
  /// ```
  /// Replaces:
  /// ```swift
  /// let sprites = getChildren().compactMap { $0 as? Sprite2D }
  /// ```
  func getChildren<T: Node>() -> [T] {
    getChildren().compactMap { $0 as? T }
  }

  /// Get all parents of a specific type.
  ///
  /// Example:
  /// ```swift
  /// let dinoViews: [Dino] = getParents()
  /// ```
  func getParents<T: Node>() -> [T] {
    var parents: [T] = []
    var cur = getParent()
    while let p = cur {
      if let t = p as? T { parents.append(t) }
      cur = p.getParent()
    }
    return parents
  }
}
