import SwiftGodot

@Godot
final class SIInvader: Area2D {
  func die() { queueFree() }
}
