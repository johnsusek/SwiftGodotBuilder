import SwiftGodot
import SwiftGodotBuilder

enum SIGroups {
  static let invader = StringName("invader")
}

struct InvaderView: GView {
  let position: Vector2

  var body: some GView {
    GNode<SIInvader> {
      Sprite2D$().texture("si_invaderA.png")
      CollisionShape2D$().shape(RectangleShape2D(x: 28, y: 20))
    }
    .position(position)
    .group(SIGroups.invader)
  }
}
