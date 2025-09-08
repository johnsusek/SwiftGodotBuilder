import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

@Godot
final class SIPlayer: Area2D {
  var speed = 320.0
  var fireCooldown = Cooldown(duration: 0.25)

  override func _process(delta: Double) {
    let left = Input.getActionStrength(action: StringName("si_left"))
    let right = Input.getActionStrength(action: StringName("si_right"))
    let dir = Double(right - left)

    if dir != 0 {
      var x = position.x + Float(dir * speed * delta)
      if x < 24 { x = 24 }
      if x > 776 { x = 776 }
      position.x = x
    }

    if Input.isActionJustPressed(action: StringName("si_fire")) {
      guard fireCooldown.tryUse() else { return }
      fire()
    }

    fireCooldown.tick(delta: delta)
  }

  private func fire() {
    var bulletPosition = position
    bulletPosition.y -= 12
    let bulletNode = BulletView(owner: .player, speed: 520, position: bulletPosition).toNode()
    getParent()?.addChild(node: bulletNode)
  }
}
