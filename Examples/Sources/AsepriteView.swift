import SwiftGodot
import SwiftGodotBuilder

struct AsepriteView: GView {
  let bottomX: Float = 240 - 48;

  var body: some GView {
    Node2D$ {
      AnimatedSprite2D$()
        .ase("player", play: "Idle")
        .position(Vector2(32, bottomX))

      AnimatedSprite2D$()
        .ase("player", play: "Crouch")
        .position(Vector2(80, bottomX))

      AnimatedSprite2D$()
        .ase("player", play: "Run")
        .position(Vector2(160, bottomX))

      AnimatedSprite2D$()
        .ase("player", play: "Sword Slash")
        .position(Vector2(224, bottomX))
    }
  }
}
