import SwiftGodot
import SwiftGodotBuilder

struct BulletView: GView {
  let owner: SIBullet.Owner
  let speed: Double
  let position: Vector2
  let size = Vector2(3, 12)

  var body: some GView {
    GNode<SIBullet> {
      ColorRect$()
        .color(owner == .player ? Color(r: 1, g: 1, b: 1, a: 1) : Color(r: 1, g: 0.6, b: 0.3, a: 1))
        .configure { $0.setSize(size) }

      CollisionShape2D$()
        .shape(RectangleShape2D(w: size.x, h: size.y))
    }
    .position(position)
    .bulletOwner(owner)
    .speed(speed)
    .on(\.areaEntered) { b, other in b.handleHit(other) }
  }
}
