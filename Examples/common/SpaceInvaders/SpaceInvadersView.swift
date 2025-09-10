import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

struct SpaceInvadersView: GView {
  let worldW: Double = 800
  let worldH: Double = 600

  private let invaderCols = 11
  private let invaderRows = 5
  private let bunkerCount = 3
  private let bunkerW = 8
  private let bunkerSize = Vector2(12, 10)
  private let startX = 160.0, gap = 240.0, y = 480.0

  private let player = Ref<SIPlayer>()

  init() {
    GodotRegistry.append(contentsOf: [SIWorld.self, SIPlayer.self, SIInvader.self, SIBullet.self, SIShield.self])
    SIActions.install(clearExisting: true)
  }

  var body: some GView {
    GNode<SIWorld> {
      // Player ship
      GNode<SIPlayer>() {
        Sprite2D$().res(\.texture, "si_player.png")
        CollisionShape2D$().shape(RectangleShape2D(w: 36.0, h: 16.0))
      }
      .position(Vector2(400, 560))
      .ref(player)

      // Shield blocks
      Node2D$ {
        for b in 0 ..< bunkerCount {
          let baseX = startX + Double(b) * gap
          for i in 0 ..< bunkerW {
            let bx = Float(baseX + Double(i) * (Double(bunkerSize.x) + 2))
            ShieldView(position: Vector2(bx, Float(y)))
          }
        }
      }
    } make: {
      let w = SIWorld(worldW: worldW, worldH: worldH)
      w.player = player
      return w
    }
  }
}
