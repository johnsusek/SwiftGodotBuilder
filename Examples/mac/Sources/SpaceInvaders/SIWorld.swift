import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

@Godot
final class SIWorld: Node2D {
  var worldW: Double = 800
  var worldH: Double = 600

  /// We use Refs inside our game classes because:
  /// 1) Godot owns node lifetimes. A strong Swift reference could keep a node
  /// alive after queueFree(). Using a weak wrapper (Ref) avoids leaks and stale pointers.
  /// 2) The .ref(player) on the SIPlayer runs **when the player node is built**,
  /// but the `make:` for `SIWorld` executes **before** building children.
  var player: Ref<SIPlayer>?

  // Fleet motion
  var dir: Float = 1 // +1 right, -1 left
  var speed: Double = 40
  var stepDown: Float = 16
  var edgeMargin: Float = 24

  // Alien fire
  var alienFireCooldown = Cooldown(duration: 0.6)
  var rng = SystemRandomNumberGenerator()

  private var invaders: [SIInvader] { nodes(inGroup: SIGroups.invader) }

  convenience init(worldW: Double, worldH: Double) {
    self.init()
    self.worldW = worldW
    self.worldH = worldH
  }

  override func _process(delta: Double) {
    alienFireCooldown.tick(delta: delta)
    moveFleet(delta: delta)
    tryAlienFire()
    checkWinLose()
  }

  private func moveFleet(delta: Double) {
    let alive = invaders
    if alive.isEmpty { return }

    let dx = Float(speed * delta) * dir
    for inv in alive {
      inv.position.x += dx
    }

    var hitEdge = false
    for inv in alive where inv.position.x < edgeMargin || inv.position.x > Float(worldW) - edgeMargin {
      hitEdge = true; break
    }
    if !hitEdge { return }

    dir *= -1
    for inv in alive {
      inv.position.y += stepDown
    }
    speed = min(240, speed * 1.04)
  }

  private func tryAlienFire() {
    if !alienFireCooldown.ready { return }

    let alive = invaders
    if alive.isEmpty { return }

    let columnW: Float = 48
    let grouped = Dictionary(grouping: alive, by: { Int($0.position.x / columnW) })

    guard let col = grouped.keys.randomElement(using: &rng),
          let stack = grouped[col],
          let shooter = stack.max(by: { $0.position.y < $1.position.y }) else { return }

    var bulletPosition = shooter.position
    bulletPosition.y += 12
    let node = BulletView(owner: .alien, speed: 520, position: bulletPosition).toNode()
    addChild(node: node)

    _ = alienFireCooldown.tryUse() // consume only after we actually fire
  }

  private func checkWinLose() {
    // `invaders` is a computed snapshot, so we get it just once before working w/ it
    let alive = invaders

    if alive.isEmpty {
      newWave()
      return
    }

    for inv in alive where inv.position.y > Float(worldH - 120) {
      gameOver()
      return
    }
  }

  private func newWave() {
    speed = 40
    dir = 1
    let startX: Float = 120, startY: Float = 100
    let dx: Float = 48, dy: Float = 36
    let rows = 5, cols = 11

    for r in 0 ..< rows {
      for c in 0 ..< cols {
        let p = Vector2(startX + Float(c) * dx, startY + Float(r) * dy)
        addChild(node: InvaderView(position: p).toNode())
      }
    }
  }

  private func gameOver() {
    speed = 40
    dir = 1
    player?.node?.position = Vector2(400, 560)

    for inv in invaders {
      inv.queueFree()
    }
  }
}
