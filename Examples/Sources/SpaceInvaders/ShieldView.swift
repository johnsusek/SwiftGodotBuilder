import SwiftGodot
import SwiftGodotBuilder

struct ShieldView: GView {
  let position: Vector2
  let shield = Ref<SIShield>()
  let colorRect = Ref<ColorRect>()

  var body: some GView {
    GNode<SIShield> {
      ColorRect$()
        .color(Color(r: 0.4, g: 1.0, b: 0.4, a: 1))
        .configure { $0.setSize(Vector2(12, 10)) }
        .ref(colorRect)
      CollisionShape2D$().shape(RectangleShape2D(w: 12.0, h: 10.0))
    }
    .position(position)
    .ref(shield)
  }
}
