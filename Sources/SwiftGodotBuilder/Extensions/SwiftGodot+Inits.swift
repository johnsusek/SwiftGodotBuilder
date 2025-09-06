import SwiftGodot

/// Convenience inits for Godot types.

public extension RectangleShape2D {
  /// Convenience initializer.
  convenience init(x: Float, y: Float) {
    self.init()
    size = Vector2(x: x, y: y)
  }

  convenience init(size: Vector2) {
    self.init()
    self.size = size
  }
}

public extension CircleShape2D {
  /// Convenience initializer.
  convenience init(radius: Double) {
    self.init()
    self.radius = radius
  }
}

public extension CapsuleShape2D {
  /// Convenience initializer.
  convenience init(radius: Double, height: Double) {
    self.init()
    self.radius = radius
    self.height = height
  }
}

public extension Vector2 {
  /// Convenience initializer.
  init(_ x: Float, _ y: Float) {
    self.init(x: x, y: y)
  }
}
