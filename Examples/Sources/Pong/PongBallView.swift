import SwiftGodot
import SwiftGodotBuilder

private typealias Config = PongConfig

struct PongBallView: GView {
  var body: some GView {
    let audioPlayer = Ref<AudioStreamPlayer2D>()

    return GNode<Ball>("Ball") {
      AudioStreamPlayer2D$()
        .res(\.stream, "ball.wav")
        .ref(audioPlayer)

      Sprite2D$()
        .res(\.texture, "ball.png")

      CollisionShape2D$()
        .shape(RectangleShape2D(w: Config.ballRadius * 2, h: Config.ballRadius * 2))
    }
    .on(\.areaEntered) { ball, area in
      if area is Paddle {
        ball.velocity.x = -ball.velocity.x

        guard let player = audioPlayer.node else { return }
        player.play()
      }
    }
  }
}
