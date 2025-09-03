import SwiftGodot
import SwiftGodotBuilder

struct PongPaddleView: GView {
  let side: String
  let position: Vector2
  let color: Color

  var body: some GView {
    GNode<Paddle> {
      Sprite2D$()
        .texture("paddle.png")
        .modulate(color)
        .position(position)

      CollisionShape2D$().shape(RectangleShape2D(x: 8, y: 32))
    } make: {
      Paddle(side: side)
    }
  }
}

struct PongBallView: GView {
  var body: some GView {
    GNode<Ball>("Ball") {
      Sprite2D$().texture("ball.png")
      CollisionShape2D$().shape(RectangleShape2D(x: 8, y: 8))
    }
    .on(\.areaEntered) { ball, area in
      if area is Paddle {
        ball.velocity.x = -ball.velocity.x
      }
    }
  }
}

struct PongView: GView {
  init() {
    GodotRegistry.append(contentsOf: [Ball.self, Paddle.self])
    PongActions.install(clearExisting: true)
  }

  var body: some GView {
    Node2D$ {
      Sprite2D$()
        .texture("separator.png")
        .position(Vector2(400, 300))

      PongPaddleView(side: "left", position: Vector2(50, 300), color: Color(r: 0, g: 1, b: 1, a: 1))
      PongPaddleView(side: "right", position: Vector2(750, 300), color: Color(r: 1, g: 0, b: 1, a: 1))
    }
  }
}

@Godot
class Ball: Area2D {
  var velocity = Vector2(300, 300)

  override func _process(delta: Double) {
    position += velocity * delta

    if position.y < 0 || position.y > 600 {
      velocity.y = -velocity.y
    }

    if position.x < 0 || position.x > 800 {
      position = Vector2(400, 300)
    }
  }
}

@Godot
class Paddle: Area2D {
  let MOVE_SPEED = 300.0
  var side = "left"

  convenience init(side: String) {
    self.init()
    self.side = side
  }

  override public func _process(delta: Double) {
    let input = Input.getActionStrength(action: StringName(side + "_move_down")) - Input.getActionStrength(action: StringName(side + "_move_up"))
    let newPos = position.y + Float(input * MOVE_SPEED * delta)
    position.y = min(600 - 16, max(16, newPos))
  }
}

let PongActions = Actions {
  ActionRecipes.axisUD(
    namePrefix: "left_move",
    device: 0,
    axis: .leftY,
    dz: 0.2,
    keyDown: .s,
    keyUp: .w,
    btnDown: .dpadDown,
    btnUp: .dpadUp
  )

  ActionRecipes.axisUD(
    namePrefix: "right_move",
    device: 1,
    axis: .leftY,
    dz: 0.2,
    keyDown: .down,
    keyUp: .up,
    btnDown: .dpadDown,
    btnUp: .dpadUp
  )
}
