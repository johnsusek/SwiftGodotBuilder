import SwiftGodot

/// Aggregates a built `SpriteFrames` resource, optional per-frame offsets,
/// and the suggested default animation name.
///
/// Use ``buildFrames(_:options:)`` to populate this from an Aseprite export.
struct BuiltFrames {
  /// The Godot `SpriteFrames` resource containing animations and frames.
  let frames: SpriteFrames
  /// Per-animation, per-frame local offsets to compensate for trimming.
  ///
  /// Keys are animation names; inner keys are the **animation-local** frame
  /// indices (0-based) as added to `SpriteFrames`. Values are offsets applied
  /// at render time (e.g. to a `Sprite2D`), typically when `AseOptions.trimming`
  /// is `.applyPivotOrCenter`.
  let perFrameOffsets: [StringName: [Int: Vector2]]
  /// The default animation to select initially, if any.
  let defaultAnim: String?
}

/// Builds a `SpriteFrames` resource (and optional per-frame offsets) from
/// decoded Aseprite data and user options.
///
/// - Note: When timing mode is `.exactDelays`, `SpriteFrames.animation_speed` is set
///   to `0` and per-frame durations are seconds. For the other modes, `animation_speed`
///   is the chosen FPS and per-frame durations are **frame units** (integers).
func buildFrames(_ decoded: AseDecoded, options: AseOptions) -> BuiltFrames {
  let file = decoded.file
  let keys = decoded.orderedKeys
  let atlas = ResourceLoader.load(path: decoded.atlasPath) as? Texture2D
  let frames = SpriteFrames()
  var offsetsByAnim: [StringName: [Int: Vector2]] = [:]

  let tags = file.meta.frameTags.filter { options.includeTags($0.name) }
  let useTags = tags.isEmpty
    ? [AseTag(name: "default", from: 0, to: max(0, keys.count - 1), direction: .forward)]
    : tags

  for tag in useTags {
    let animName = StringName(options.tagMap[tag.name] ?? tag.name)
    frames.addAnimation(anim: animName)
    frames.setAnimationLoop(anim: animName, loop: true)

    let indices = indicesFor(tag: tag)
    let durationsMs = indices.map { file.frames[keys[$0]]!.duration }
    let timing = pickTiming(durationsMs, options.timing)

    // Configure animation speed and compute a frame "duration" mapper.
    let fps: Double
    let frameDuration: (Int) -> Double // units if fps>0, seconds if fps==0

    switch timing {
    case let .uniform(fixedFPS):
      fps = fixedFPS
      frameDuration = { _ in 1.0 } // one unit per frame at fixed FPS
    case let .gcd(cappedFPS):
      fps = cappedFPS
      // units = round(ms * fps / 1000), min 1
      frameDuration = { ms in max(1.0, (Double(ms) * fps / 1000.0).rounded()) }
    case .exact:
      fps = 0
      frameDuration = { ms in Double(ms) / 1000.0 } // seconds
    }

    frames.setAnimationSpeed(anim: animName, fps: fps)

    var perAnimOffsets: [Int: Vector2] = [:]

    for (animFrameIndex, sourceIndex) in indices.enumerated() {
      let key = keys[sourceIndex]
      guard let f = file.frames[key] else { continue }

      let atlasTex = AtlasTexture()
      atlasTex.atlas = atlas
      atlasTex.region = Rect2(
        x: Float(f.frame.x), y: Float(f.frame.y),
        width: Float(f.frame.w), height: Float(f.frame.h)
      )

      frames.addFrame(anim: animName, texture: atlasTex, duration: frameDuration(f.duration))

      if options.trimming == .applyPivotOrCenter, f.trimmed {
        perAnimOffsets[animFrameIndex] = offsetForTrimmed(frame: f, slices: file.meta.slices) ?? .zero
      }
    }

    if !perAnimOffsets.isEmpty { offsetsByAnim[animName] = perAnimOffsets }
  }

  let first = useTags.first.map { options.tagMap[$0.name] ?? $0.name }
  return .init(frames: frames, perFrameOffsets: offsetsByAnim, defaultAnim: first)
}

/// Internal representation of chosen timing strategy after considering
/// source delays and option caps.
private enum PickedTiming { case uniform(Double), gcd(Double), exact }

/// Expands an Aseprite tag's inclusive range into a sequence of source frame indices,
/// honoring the tag's playback direction.
///
/// - Parameter tag: The Aseprite tag (name/from/to/direction).
/// - Returns: Source frame indices (into `decoded.orderedKeys`) for this animation.
private func indicesFor(tag: AseTag) -> [Int] {
  let a = tag.from, b = tag.to

  switch tag.direction {
  case .forward:
    return a <= b ? Array(a ... b) : Array(stride(from: a, through: b, by: -1))
  case .reverse:
    return a <= b ? Array((a ... b).reversed()) : Array(stride(from: a, through: b, by: -1))
  case .pingpong:
    if a == b { return [a] }
    let forward = a <= b ? Array(a ... b) : Array(stride(from: a, through: b, by: -1))
    let back = Array(forward.dropLast().dropFirst().reversed())
    return forward + back
  }
}

/// Chooses a timing mode based on `AseOptions.Timing`, optionally computing a
/// GCD-normalized FPS capped by `cap`.
///
/// - Parameters:
///   - ms: Per-frame delays in milliseconds for the source frames of an animation.
///   - mode: Desired timing mode from options.
/// - Returns: A ``PickedTiming`` indicating FPS and duration semantics.
///
/// - Important: In `.delaysGCD(cap)`, FPS is `min(cap, 1000 / max(1, gcd(ms)))`.
private func pickTiming(_ ms: [Int], _ mode: AseOptions.Timing) -> PickedTiming {
  switch mode {
  case let .uniformFPS(fps): return .uniform(fps)
  case .exactDelays: return .exact
  case let .delaysGCD(cap):
    let g = gcdArray(ms)
    let fps = min(cap, 1000.0 / Double(max(1, g)))
    return .gcd(fps)
  }
}

/// Computes the greatest common divisor for an array of integers.
/// Returns `1000` for an empty array (treat as 1 second base).
///
/// - Parameter xs: Input integers.
/// - Returns: `gcd(xs)` (non-negative).
private func gcdArray(_ xs: [Int]) -> Int {
  if xs.isEmpty { return 1000 }
  return xs.reduce(xs[0]) { a, b in gcd(a, b) }
}

/// Euclidean GCD for two integers (order-insensitive).
///
/// - Parameters:
///   - a: First integer.
///   - b: Second integer.
/// - Returns: `gcd(|a|, |b|)`.
private func gcd(_ a: Int, _ b: Int) -> Int {
  var x = abs(a), y = abs(b)

  while y != 0 {
    let t = x % y
    x = y
    y = t
  }

  return x
}

/// Computes the local offset that repositions a trimmed frame back onto the
/// original canvas using the chosen pivot (or canvas center).
///
/// Offset is measured so that when applied to a `Sprite2D`'s position (or to a
/// per-frame draw offset), the visual remains aligned as if untrimmed.
///
/// - Parameters:
///   - frame: The frame's rects and sizes (trim metadata).
///   - slices: Aseprite slices; prefers a slice named `"pivot"` with a pivot,
///     then any slice with a pivot; otherwise defaults to canvas center.
/// - Returns: The offset vector, or `nil` if nothing should be applied.
private func offsetForTrimmed(frame: AseFrame, slices: [AseSlice]) -> Vector2? {
  let canvasW = Float(frame.sourceSize.w), canvasH = Float(frame.sourceSize.h)
  let pivot = pivotFor(frameIndex: nil, slices: slices) ?? Vector2(x: canvasW * 0.5, y: canvasH * 0.5)
  let spriteSource = frame.spriteSourceSize
  let ox = Float(spriteSource.x) - pivot.x + Float(frame.frame.w) * 0.5
  let oy = Float(spriteSource.y) - pivot.y + Float(frame.frame.h) * 0.5

  return Vector2(x: ox, y: oy)
}

/// Resolves a per-frame pivot from slices by priority:
/// 1) Slice named `"pivot"` with a pivot for the frame (or any pivot if none frame-specific).
/// 2) Any slice with a pivot for the frame (or any pivot).
///
/// - Parameters:
///   - frameIndex: When provided, tries to match a pivot keyed to that frame.
///   - slices: Aseprite slices from metadata.
/// - Returns: The chosen pivot in canvas coordinates, or `nil` if none exist.
private func pivotFor(frameIndex: Int?, slices: [AseSlice]) -> Vector2? {
  if let pivotSlice = slices.first(where: { $0.name == "pivot" }) {
    if let key = frameIndex
      .flatMap({ fi in pivotSlice.keys.first(where: { $0.frame == fi && $0.pivot != nil }) })
      ?? pivotSlice.keys.first(where: { $0.pivot != nil }),
      let p = key.pivot
    {
      return Vector2(x: Float(p.x), y: Float(p.y))
    }
  }

  for slice in slices {
    if let key = frameIndex
      .flatMap({ fi in slice.keys.first(where: { $0.frame == fi && $0.pivot != nil }) })
      ?? slice.keys.first(where: { $0.pivot != nil }),
      let p = key.pivot
    {
      return Vector2(x: Float(p.x), y: Float(p.y))
    }
  }
  return nil
}
