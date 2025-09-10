import SwiftGodot

@Godot
final class SIBullet: Area2D {
  var bulletOwner: SIBullet.Owner = .player
  var speed: Double = 500

  enum Owner { case player, alien }

  override func _process(delta: Double) {
    let dy: Float = bulletOwner == .player ? -1 : 1
    position.y += Float(speed * delta) * dy
    if position.y < -16 || position.y > 616 { queueFree() }
  }

  func handleHit(_ other: Area2D?) {
    guard let other else { return }
    switch bulletOwner {
    case .player:
      if let inv = other as? SIInvader {
        inv.die()
        queueFree()
      }
      if let shield = other as? SIShield {
        shield.hit()
        queueFree()
      }
    case .alien:
      if let player = other as? SIPlayer {
        player.queueFree()
        queueFree()
      }
      if let shield = other as? SIShield {
        shield.hit()
        queueFree()
      }
    }
  }
}
