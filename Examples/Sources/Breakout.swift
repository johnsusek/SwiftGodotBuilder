import SwiftGodot
import SwiftGodotBuilder

// MARK: - View

struct BreakoutView: GView {
  let worldW: Double = 800
  let worldH: Double = 600

  init() {
    GodotRegistry.append(contentsOf: [BOBall.self, BOBrick.self, BOPaddle.self])
    breakoutActions.install(clearExisting: true)
  }

  var body: some GView {
    Node2D$ {
      // Ball
      GNode<BOBall>("Ball") {
        Sprite2D$().texture("ball.png")
        CollisionShape2D$().shape(RectangleShape2D(x: 8, y: 8))
      }
      .position(Vector2(Float(worldW / 2), Float(worldH / 2)))
      .on(\.areaEntered) { ball, area in
        guard let area else { return }
        switch area {
        case is BOPaddle:
          ball.bounceFromPaddle(paddleY: area.position.y)
        case let b as BOBrick:
          ball.bounceFromBrick()
          b.queueFree()
        default: break
        }
      }

      // Paddle
      GNode<BOPaddle>("Paddle") {
        Sprite2D$()
          .texture("bo_paddle.png")
          .modulate(Color(r: 0.9, g: 0.9, b: 1, a: 1))
        CollisionShape2D$().shape(RectangleShape2D(x: 64, y: 12))
      } make: {
        BOPaddle(worldW: worldW)
      }
      .position(Vector2(Float(worldW / 2), Float(worldH - 40)))

      // Bricks grid
      Node2D$ {
        let cols = 12, rows = 6
        let startX: Double = 64, startY: Double = 60
        let dx: Double = 56, dy: Double = 22
        for r in 0 ..< rows {
          for c in 0 ..< cols {
            GNode<BOBrick> {
              Sprite2D$().texture("bo_brick.png")
              CollisionShape2D$().shape(RectangleShape2D(x: 48, y: 16))
            }
            .position(Vector2(Float(startX + Double(c) * dx), Float(startY + Double(r) * dy)))
          }
        }
      }
    }
  }
}

// MARK: - Actions

let breakoutActions = Actions {
  ActionRecipes.axisLR(
    namePrefix: "pad",
    device: 0,
    axis: .leftX,
    dz: 0.25,
    keyLeft: .a,
    keyRight: .d,
    btnLeft: .dpadLeft,
    btnRight: .dpadRight
  )
}

// MARK: - Gameplay Nodes

@Godot
class BOBall: Area2D {
  var velocity = Vector2(260, 260)
  var bounds = Rect2(position: Vector2(0, 0), size: Vector2(800, 600))

  override func _process(delta: Double) {
    position += velocity * delta

    // Walls: left/right: bounce
    if position.x < 4 || position.x > bounds.size.x - 4 {
      velocity.x = -velocity.x
    }

    // Ceiling: bounce
    if position.y < 4 {
      velocity.y = -velocity.y
    }

    // Fall below: reset
    if position.y > bounds.size.y + 16 {
      resetBall()
    }
  }

  func bounceFromBrick() { velocity.y = -velocity.y }

  func bounceFromPaddle(paddleY _: Float) {
    velocity.y = -abs(velocity.y)
    // Small spice: add a tiny random x tweak so it doesn't lock into vertical bounces.
    let tweak = Float.random(in: -40 ... 40)
    velocity.x += tweak
  }

  func resetBall() {
    position = Vector2(400, 300)
    velocity = Vector2(260, -260)
  }
}

@Godot
class BOPaddle: Area2D {
  var speed = 480.0
  var worldW = 0.0

  convenience init(worldW: Double) {
    self.init()
    self.worldW = worldW
  }

  override func _process(delta: Double) {
    let left = Input.getActionStrength(action: StringName("pad_left"))
    let right = Input.getActionStrength(action: StringName("pad_right"))
    let dir = Double(right - left)
    if dir == 0 { return }
    let newPos = position.x + Float(dir * speed * delta)
    position.x = max(40, min(newPos, Float(worldW - 40)))
  }
}

@Godot
class BOBrick: Area2D {}
