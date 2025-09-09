import SwiftGodot
import SwiftGodotPatterns

public extension GNode where T: CanvasItem {
  /// Example:
  ///
  /// ```swift
  /// // Bullets that vanish off-screen or after 4 seconds (whichever first)
  /// Node2D$("Bullet") {
  ///   Sprite2D$().res(\.texture, "bullet.png")
  /// }
  /// .autoDespawn(seconds: 4, whenOffscreen: true)
  /// ```
  ///
  /// Example:
  /// ```swift
  /// // Particles that only time-out (no off-screen checks)
  /// GNode<GPUParticles2D>()
  ///   .autoDespawn(seconds: 1.5, whenOffscreen: false)
  /// ```
  func autoDespawn(seconds: Double? = nil,
                   whenOffscreen: Bool = true,
                   offscreenDelay: Double = 0,
                   onDespawn: (() -> Void)? = nil) -> Self
  {
    var s = self

    s.ops.append { host in
      let m = AutoDespawn2D()
      m.seconds = seconds
      m.offscreen = whenOffscreen
      m.offscreenDelay = offscreenDelay
      m.onDespawn = onDespawn

      host.addChild(node: m)
    }

    return s
  }

  /// Example:
  ///
  /// ```swift
  /// // Enemies that return to a pool when they leave the camera view
  /// let pool = ObjectPool<Node2D>(factory: { Node2D() }) // your actual enemy type here
  ///
  /// Node2D$("Enemy") {
  ///  // ... visuals, collision, AI ...
  /// }
  /// .autoDespawnToPool(pool, whenOffscreen: true, offscreenDelay: 0.25)
  /// ```
  ///
  func autoDespawnToPool(_ pool: ObjectPool<T>,
                         seconds: Double? = nil,
                         whenOffscreen: Bool = true,
                         offscreenDelay: Double = 0,
                         onDespawn: (() -> Void)? = nil) -> Self
  {
    var s = self

    s.ops.append { host in
      let m = AutoDespawn2D()
      m.seconds = seconds
      m.offscreen = whenOffscreen
      m.offscreenDelay = offscreenDelay
      m.onDespawn = onDespawn

      m.releaseToPool = { anyNode in
        if let typed = anyNode as? T {
          pool.release(typed)
        } else {
          anyNode.queueFree()
        }
      }

      host.addChild(node: m)
    }

    return s
  }
}
