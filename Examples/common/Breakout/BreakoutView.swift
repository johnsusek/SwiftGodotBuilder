import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

private typealias Config = BreakoutConfig

struct BreakoutView: GView {
  init() {
    GodotRegistry.append(contentsOf: [BOBall.self, BOBrick.self, BOPaddle.self])
    breakoutActions.install(clearExisting: true)
  }

  var body: some GView {
    Node2D$ {
      Node2D$ {
        // Ball
        GNode<BOBall>("Ball") {
          Sprite2D$()
            .res(\.texture, "ball.png")

          CollisionShape2D$()
            .shape(RectangleShape2D(w: Config.ballRadius * 2, h: Config.ballRadius * 2))
        }
        .position(Vector2(x: Config.viewW / 2, y: Config.viewH / 2))
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
            .res(\.texture, "bo_paddle.png")
            .modulate(Color(r: 0.9, g: 0.9, b: 1, a: 1))

          CollisionShape2D$()
            .shape(RectangleShape2D(w: Config.paddleW, h: Config.paddleH))
        }
        .position(Vector2(x: Config.viewW / 2, y: Config.viewH - Config.paddleMargin))

        // Bricks
        Node2D$ {
          for r in 0 ..< Config.brickRows {
            for c in 0 ..< Config.brickCols {
              GNode<BOBrick> {
                Sprite2D$()
                  .res(\.texture, "bo_brick.png")

                CollisionShape2D$()
                  .shape(RectangleShape2D(w: Config.brickW - 6.0, h: Config.brickH - 6.0))
              }
              .position(Vector2(Config.bricksX + Float(c) * Config.brickW, Config.bricksY + Float(r) * Config.brickH))
            }
          }
        }
      }

      Camera2D$()
        .position(Vector2(Config.viewW / 2, Config.viewH / 2))
    }
  }
}

private let breakoutActions = Actions {
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
