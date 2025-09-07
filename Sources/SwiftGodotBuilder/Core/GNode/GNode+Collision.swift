import SwiftGodot

public extension GNode where T: CollisionObject2D {
  func layers(_ set: Physics2DLayer) -> Self {
    var s = self
    s.ops.append { $0.collisionLayer = UInt32(set.rawValue) }
    return s
  }

  func mask(_ set: Physics2DLayer) -> Self {
    var s = self
    s.ops.append { $0.collisionMask = UInt32(set.rawValue) }
    return s
  }
}
