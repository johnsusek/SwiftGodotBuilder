import SwiftGodot

public extension GNode where T: AnimatedSprite2D {
  /// Attaches an Aseprite spritesheet (JSON + atlas) to an `AnimatedSprite2D`
  /// and optionally starts playback.
  ///
  /// - Parameters:
  ///   - jsonPath: Path to the Aseprite JSON **without res://**.
  ///   - options: Controls tag inclusion/mapping, timing, trimming, key ordering.
  ///   - play: Optional animation name to start immediately after assignment.
  ///
  /// - Note: Animation names are case-sensitive.
  ///
  /// - Note: When trimming offsets exist, `offset` is updated on every frame
  ///   change to align trimmed frames to their original canvas using pivot data.
  ///   If no offsets are present, `offset` is reset to `.zero`.
  ///
  /// - Example:
  ///   ```swift
  ///   AnimatedSprite2D$()
  ///     .ase("player.json",
  ///          options: .init(timing: .delaysGCD(baseCap: 60),
  ///                         trimming: .applyPivotOrCenter),
  ///          play: "Run")
  ///   ```
  func ase(_ jsonPath: String, options: AseOptions = .init(), play: String? = nil) -> Self {
    var node = self

    node.ops.append { sprite in
      guard let built = try? { () -> BuiltFrames in
        let decoded = try decodeAse(jsonPath, options: options)

        return buildFrames(decoded, options: options)
      }() else { return }

      sprite.spriteFrames = built.frames

      let startName = play ?? built.defaultAnim

      if let startName { sprite.play(name: StringName(startName)) }

      if built.perFrameOffsets.isEmpty { return }

      let offsetsByAnim = built.perFrameOffsets

      let applyOffset: () -> Void = { [weak sprite] in
        guard let sprite else { return }

        let currentAnim = sprite.animation

        guard let map = offsetsByAnim[currentAnim] else { sprite.offset = .zero; return }

        sprite.offset = map[Int(sprite.frame)] ?? .zero
      }

      _ = sprite.frameChanged.connect { applyOffset() }

      applyOffset()
    }

    return node
  }
}
