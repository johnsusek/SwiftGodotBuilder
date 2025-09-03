import SwiftGodot
import SwiftGodotBuilder

private typealias Config = PongConfig

struct PongBallView: GView {
  var body: some GView {
    GNode<Ball>("Ball") {
      Sprite2D$()
        .texture("ball.png")
      CollisionShape2D$()
        .shape(RectangleShape2D(x: Config.ballRadius * 2, y: Config.ballRadius * 2))
    }
    .on(\.areaEntered) { ball, area in
      if area is Paddle {
        ball.velocity.x = -ball.velocity.x
      }
    }
  }
}
