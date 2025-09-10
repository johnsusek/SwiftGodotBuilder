import SwiftGodot

private typealias Config = BreakoutConfig

@Godot
class BOBall: Area2D {
  var velocity = Vector2(260, -260)

  override func _physicsProcess(delta: Double) {
    let dt = Float(delta)
    position.x += velocity.x * dt
    position.y += velocity.y * dt

    let viewportSize = visibleSize

    if position.x <= Config.ballRadius {
      position.x = Config.ballRadius
      velocity.x = -velocity.x
    }

    if position.x >= viewportSize.x - Config.ballRadius {
      position.x = viewportSize.x - Config.ballRadius
      velocity.x = -velocity.x
    }

    if position.y <= Config.ballRadius {
      position.y = Config.ballRadius
      velocity.y = -velocity.y
    }

    if position.y >= viewportSize.y + Config.ballRadius { resetBall() }
  }

  func bounceFromBrick() { velocity.y = -velocity.y }

  func bounceFromPaddle(paddleY _: Float) {
    velocity.y = -abs(velocity.y)
    velocity.x += Float.random(in: -40 ... 40)
  }

  func resetBall() {
    position = visibleCenter
    velocity = Vector2(260, -260)
  }
}
