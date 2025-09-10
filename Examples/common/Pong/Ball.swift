import SwiftGodot

private typealias Config = PongConfig

@Godot
class Ball: Area2D {
  var velocity = Vector2(Config.ballVelocity, Config.ballVelocity) // px/s

  override func _physicsProcess(delta: Double) {
    let dt = Float(delta)
    position.x += velocity.x * dt
    position.y += velocity.y * dt

    let viewportSize = visibleSize

    if position.y <= Config.ballRadius {
      position.y = Config.ballRadius
      velocity.y = -velocity.y
    }

    if position.y >= viewportSize.y - Config.ballRadius {
      position.y = viewportSize.y - Config.ballRadius
      velocity.y = -velocity.y
    }

    // Scoring/out-of-bounds
    if position.x <= -Config.ballRadius || position.x >= viewportSize.x + Config.ballRadius {
      position = Vector2(viewportSize.x * 0.5, viewportSize.y * 0.5)
      velocity = Vector2(Config.ballVelocity, Config.ballVelocity)
    }
  }
}
