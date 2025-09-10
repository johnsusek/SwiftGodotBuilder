import SwiftGodot

private typealias Config = PongConfig

@Godot
class Paddle: Area2D {
  var side = "left"
  let halfH = Config.paddleHeight / 2

  convenience init(side: String) {
    self.init()
    self.side = side
  }

  override func _physicsProcess(delta: Double) {
    let v = Input.getActionStrength(action: StringName("\(side)_move_down"))
      - Input.getActionStrength(action: StringName("\(side)_move_up"))
    if v == 0 { return }

    position.y += Config.paddleSpeed * Float(v * delta)

    let viewportSize = visibleSize

    if position.y < halfH {
      position.y = halfH;
      return
    }

    if position.y > viewportSize.y - halfH {
      position.y = viewportSize.y - halfH
    }
  }
}
