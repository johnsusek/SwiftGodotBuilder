import SwiftGodot

private typealias Config = BreakoutConfig

@Godot
class BOPaddle: Area2D {
  var speed = 480.0
  private var halfW: Float = Config.paddleW / 2.0

  override func _physicsProcess(delta: Double) {
    let dir = Double(Input.getActionStrength(action: StringName("pad_right"))
      - Input.getActionStrength(action: StringName("pad_left")))

    if dir == 0 { return }

    position.x += Float(speed * dir * delta)

    let viewportSize = visibleSize

    if position.x < halfW {
      position.x = halfW
      return
    }

    if position.x > viewportSize.x - halfW {
      position.x = viewportSize.x - halfW
    }
  }
}
