import SwiftGodot

/// Helpers for setting collision layers and masks on `CollisionObject2D` nodes.
///
/// Example:
/// ```swift
/// let wall = GNode<StaticBody2D>()
///   .layers([.alpha, .beta])
///   .mask([.gamma])
/// ```
public extension GNode where T: CollisionObject2D {
  func collisionLayer(_ set: Physics2DLayer) -> Self {
    var s = self
    s.ops.append { $0.collisionLayer = UInt32(set.rawValue) }
    return s
  }

  func collisionMask(_ set: Physics2DLayer) -> Self {
    var s = self
    s.ops.append { $0.collisionMask = UInt32(set.rawValue) }
    return s
  }
}
