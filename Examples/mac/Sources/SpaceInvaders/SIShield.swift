import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

@Godot
final class SIShield: Area2D {
  var hp = Health(max: 3)

  override func _ready() {
    hp.onChanged = hpChanged(_:new:)
    hp.onDied = died
  }

  func died() { queueFree() }

  func hpChanged(_: Double, new: Double) {
    guard let colorRect = getNode(path: NodePath("ColorRect")) as? ColorRect else { return }
    colorRect.modulate.alpha = Float(0.4 + (0.2 * new))
  }

  func hit() { hp.damage(1) }
}
