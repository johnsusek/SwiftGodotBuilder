import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

private typealias Config = PongConfig

struct PongView: GView {
  init() {
    GodotRegistry.append(contentsOf: [Ball.self, Paddle.self])
    PongActions.install(clearExisting: true)
  }

  var body: some GView {
    Node2D$ {
      Node2D$ {
        Sprite2D$()
          .res(\.texture, "separator.png")
          .position(Vector2(Config.viewW / 2, Config.viewH / 2))

        PongBallView()

        PongPaddleView(
          side: "left",
          position: Vector2(Config.paddleWidth, Config.viewH / 2),
          color: Color(r: 0, g: 1, b: 1, a: 1)
        )

        PongPaddleView(
          side: "right",
          position: Vector2(Config.viewW - Config.paddleWidth, Config.viewH / 2),
          color: Color(r: 1, g: 0, b: 1, a: 1)
        )
      }
    }
  }
}

private let PongActions = Actions {
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
