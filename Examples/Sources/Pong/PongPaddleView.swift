import SwiftGodot
import SwiftGodotBuilder

private typealias Config = PongConfig

struct PongPaddleView: GView {
  let side: String
  let position: Vector2
  let color: Color

  var body: some GView {
    GNode<Paddle> {
      Sprite2D$()
        .texture("paddle.png")
        .modulate(color)

      CollisionShape2D$()
        .shape(RectangleShape2D(x: Config.paddleWidth, y: Config.paddleHeight))
    } make: {
      Paddle(side: side)
    }
    .position(position)
  }
}
