import SwiftGodot

/// Options controlling how Aseprite exports are interpreted when building
/// Godot `SpriteFrames` (timing, tag selection/mapping, trimming behavior,
/// and optional frame-key ordering).
public struct AseOptions {
  /// Controls how per-frame delays from Aseprite are mapped into Godot timing.
  ///
  /// Godot's `SpriteFrames` supports two timing modes:
  /// - **FPS-based**: `animation_speed` = FPS, each frame has a *unit* duration (integer).
  /// - **Exact per-frame seconds**: `animation_speed` = `0`, each frame stores seconds.
  public enum Timing {
    /// Use a fixed frames-per-second value. Each frame contributes one unit at that FPS.
    case uniformFPS(Double)
    /// Preserve Aseprite's millisecond delays as exact seconds (Godot FPS = `0`).
    case exactDelays
    /// Quantize delays to the greatest common divisor (GCD) timeline, capped at `baseCap` FPS.
    ///
    /// This yields integer frame units (good for editor scrubbing) while staying close to
    /// source timings: `fps = min(baseCap, 1000 / gcd(ms))`.
    case delaysGCD(baseCap: Double = 60)
  }

  /// How to handle trimmed frames relative to the original canvas and pivot metadata.
  public enum Trimming {
    /// Ignore trimming metadata; no offsets are produced.
    case ignore
    /// Apply offsets so trimmed rectangles render as if placed back on the full canvas,
    /// using the `"pivot"` slice when present, otherwise any slice pivot, else canvas center.
    case applyPivotOrCenter
  }

  /// Predicate that selects which Aseprite *tags* become animations.
  ///
  /// The closure receives the tag name; return `true` to include it.
  /// Defaults to including all tags. If no tags pass this filter, a single
  /// `"default"` animation is synthesized that spans all frames.
  public var includeTags: (String) -> Bool = { _ in true }

  /// Optional mapping from Aseprite tag names to animation names in Godot.
  ///
  /// Values override the emitted animation names; unlisted tags keep their original names.
  public var tagMap: [String: String] = [:]

  /// Timing strategy applied when generating `SpriteFrames` animations.
  public var timing: Timing = .delaysGCD()

  /// Trimming strategy used when producing optional per-frame offsets.
  public var trimming: Trimming = .ignore

  /// Optional override for the ordering of frame dictionary keys.
  public var keyOrdering: (([String]) -> [String])?

  /// Memberwise initializer with sensible defaults.
  public init(includeTags: @escaping (String) -> Bool = { _ in true },
              tagMap: [String: String] = [:],
              timing: Timing = .delaysGCD(),
              trimming: Trimming = .ignore,
              keyOrdering: (([String]) -> [String])? = nil)
  {
    self.includeTags = includeTags
    self.tagMap = tagMap
    self.timing = timing
    self.trimming = trimming
    self.keyOrdering = keyOrdering
  }
}

/// Convenience that decodes an Aseprite JSON file and builds a `SpriteFrames`
/// resource using the provided options.
///
/// This is a shorthand for:
/// ```swift
/// let decoded = try decodeAse(path, options: options)
/// let built = buildFrames(decoded, options: options)
/// let frames = built.frames
/// ```
public func AseSpriteFrames(_ jsonPath: String, options: AseOptions = .init()) throws -> SpriteFrames {
  let decoded = try decodeAse(jsonPath, options: options)
  return buildFrames(decoded, options: options).frames
}

/// Returns the raw Aseprite **slice keys** grouped by slice name.
///
/// This is useful for querying pivots or custom per-frame regions directly from
/// metadata without building animations.
public func AseSlices(_ jsonPath: String) throws -> [String: [AseSliceKey]] {
  let decoded = try decodeAse(jsonPath, options: .init())
  return Dictionary(uniqueKeysWithValues: decoded.file.meta.slices.map { ($0.name, $0.keys) })
}
