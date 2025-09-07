import SwiftGodot

public extension GNode where T: AnimatedSprite2D {
  /// Attaches an Aseprite spritesheet (JSON + atlas) to an `AnimatedSprite2D`
  /// and optionally starts playback.
  ///
  /// - Parameters:
  ///   - jsonPath: Path to the Aseprite JSON **without res://**. As a shorthand
  ///               you can leave off the `.json` suffix.
  ///   - layer: Optional layer name to filter frames by, uses first layer if `nil`.
  ///   - options: Optional controls for tag inclusion/mapping, timing, trimming, key ordering.
  ///   - play: Optional animation name to start immediately after assignment.
  ///
  /// - Note: Animation names are case-sensitive.
  ///
  /// - Example:
  ///   ```swift
  ///   AnimatedSprite2D$().ase("player.json", play: "Idle")
  ///   AnimatedSprite2D$().ase("enemy", layer: "Hurt", play: "Attack")
  ///   ```

  func ase(_ jsonPath: String, layer: String? = nil, options: AseOptions = .init(), play: String? = nil) -> Self {
    var node = self

    node.ops.append { sprite in
      guard let built = try? { () -> BuiltFrames in
        let fullJsonPath = jsonPath.hasSuffix(".json") ? jsonPath : jsonPath + ".json"
        let decoded = try decodeAse(fullJsonPath, options: options, layer: layer)
        return buildFrames(decoded, options: options)
      }() else { return }

      sprite.spriteFrames = built.frames

      let startName = play ?? built.defaultAnim
      if let startName {
        sprite.play(name: StringName(startName))
      }

      if built.perFrameOffsets.isEmpty { return }

      let offsetsByAnim = built.perFrameOffsets

      let applyOffset: () -> Void = { [weak sprite] in
        guard let sprite else { return }
        let currentAnim = sprite.animation
        guard let map = offsetsByAnim[currentAnim] else {
          sprite.offset = .zero
          return
        }
        sprite.offset = map[Int(sprite.frame)] ?? .zero
      }

      _ = sprite.frameChanged.connect { applyOffset() }

      applyOffset()
    }

    return node
  }
}
