import SwiftGodot
import SwiftGodotBuilder

enum SIGroups {
  static let invader = StringName("invader")
}

struct InvaderView: GView {
  let position: Vector2

  var body: some GView {
    GNode<SIInvader> {
      Sprite2D$().res(\.texture, "si_invaderA.png")
      CollisionShape2D$().shape(RectangleShape2D(w: 28.0, h: 20.0))
    }
    .position(position)
    .group(SIGroups.invader)
  }
}
