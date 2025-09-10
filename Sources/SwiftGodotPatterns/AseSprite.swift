import Foundation
import SwiftGodot

/// A Godot `AnimatedSprite2D` subclass that knows how to load
/// and play animations from an Aseprite JSON + spritesheet export.
///
/// This class wraps all the decode/build/offset logic so you can drop
/// an instance into your scene tree and configure it with a single call.
///
/// ### Features
/// - Decodes both *array* and *hash* style Aseprite JSON exports.
/// - Builds Godot `SpriteFrames` resources from Aseprite frame/timing data.
/// - Maps Aseprite *tags* to Godot animations (with optional tag filtering/mapping).
/// - Supports different timing strategies (`uniformFPS`, `exactDelays`, `delaysGCD`).
/// - Restores trimmed frames to their full-canvas positions using slice pivots or center.
/// - Applies per-frame offsets automatically during playback.
///
/// - Note: Enable the "Split Layers" option when exporting a file with multiple layers.
///
/// - Note: Animation names are case-sensitive.
///
/// - Note: You may omit the `.json` suffix when specifying the JSON path.
///
/// ### Example
/// ```swift
/// // Using convenience init
/// let enemy = AseSprite("enemy.json",
///                       layer: "Base",
///                       options: .init(trimming: .applyPivotOrCenter),
///                       autoplay: "Walk")
///
/// // Using builder
/// let player = GNode<AseSprite>("Player", path: "player.json", autoplay: "Idle")
/// ```
@Godot
public final class AseSprite: AnimatedSprite2D {
  // MARK: Configuration

  /// Path to the Aseprite JSON (may omit `.json` suffix).
  public var sourcePath: String = ""

  /// Optional layer filter (only frames from this Ase layer are included).
  public var layerName: String? = nil

  /// Options controlling tag inclusion, timing, trimming, and ordering.
  public var aseOptions: AseOptions = .init()

  /// Optional animation to start automatically
  // if not set, uses the first tag.
  public var autoplayAnimation: String? = nil

  // MARK: Internal state

  private var offsetsByAnim: [StringName: [Int: Vector2]] = [:]
  private var defaultAnimName: String? = nil
  private var lastConfig: (path: String, layer: String?, options: AseOptions, autoplay: String?)?

  // MARK: Lifecycle

  /// Initializes and immediately loads an Aseprite export.
  ///
  /// - Parameters:
  ///   - path: Path to the Aseprite JSON (may omit `.json` suffix).
  ///   - layer: Optional layer filter name
  // pass `nil` to include all layers.
  ///   - options: Ase decoding/build options (defaults to `.delaysGCD` timing).
  ///   - autoplay: Optional animation name to start immediately.
  public convenience init(_ path: String,
                          layer: String? = nil,
                          options: AseOptions = .init(),
                          autoplay: String? = nil)
  {
    self.init()
    loadAse(path, layer: layer, options: options, autoplay: autoplay)
  }

  /// Loads an Aseprite export into this sprite.
  ///
  /// - Parameters:
  ///   - path: Path to the Aseprite JSON (may omit `.json` suffix).
  ///   - layer: Optional layer filter name
  // pass `nil` to include all layers.
  ///   - options: Ase decoding/build options (defaults to `.delaysGCD` timing).
  ///   - autoplay: Optional animation name to start immediately.
  public func loadAse(_ path: String,
                      layer: String? = nil,
                      options: AseOptions = .init(),
                      autoplay: String? = nil)
  {
    sourcePath = path
    layerName = layer
    aseOptions = options
    autoplayAnimation = autoplay
    buildFromAse()
  }

  override public func _ready() {
    _ = frameChanged.connect { [weak self] in self?.applyPerFrameOffset() }
    if !sourcePath.isEmpty { buildFromAse() }
  }

  // MARK: Build / Offsets

  /// Decodes, builds, and assigns the `SpriteFrames` from the configured path/options.
  private func buildFromAse() {
    let cfg = (sourcePath, layerName, aseOptions, autoplayAnimation)

    // loadAse triggers a build, then _ready can rebuild again. Track a stamp and bail if unchanged.
    if lastConfig?.path == cfg.0 && lastConfig?.layer == cfg.1 &&
      String(reflecting: lastConfig?.2) == String(reflecting: cfg.2) &&
      lastConfig?.autoplay == cfg.3 { return }

    lastConfig = cfg

    guard let built = try? { () -> BuiltFrames in
      let decoded = try Self.decodeAse(sourcePath, options: aseOptions, layer: layerName)
      return Self.buildFrames(decoded, options: aseOptions)
    }() else {
      GD.print("⚠️ AseSprite build failed for", sourcePath)
      return
    }

    spriteFrames = built.frames
    offsetsByAnim = built.perFrameOffsets
    defaultAnimName = built.defaultAnim

    let start = autoplayAnimation ?? defaultAnimName
    if let start { play(name: StringName(start)) }

    applyPerFrameOffset()
  }

  /// Applies a per-frame offset if trimming correction is enabled.
  private func applyPerFrameOffset() {
    guard !offsetsByAnim.isEmpty else {
      offset = .zero
      return
    }

    let current = animation

    guard let map = offsetsByAnim[current] else {
      offset = .zero
      return
    }

    offset = map[Int(frame)] ?? .zero
  }
}

// MARK: - Core build pipeline (static so it’s easy to test/reuse)

private extension AseSprite {
  struct AseDecoded {
    let file: AseJson
    let orderedKeys: [String]
    let atlasPath: String
  }

  enum AseError: Error { case readFailed(String) }

  static func decodeAse(_ jsonPath: String, options: AseOptions, layer: String?) throws -> AseDecoded {
    let full = jsonPath.hasSuffix(".json") ? jsonPath : jsonPath + ".json"
    let text = FileAccess.getFileAsString(path: full)
    guard !text.isEmpty else { throw AseError.readFailed(full) }

    let file = try JSONDecoder().decode(AseJson.self, from: Data(text.utf8))
    let atlasPath = file.meta.image.isEmpty ? withExtension(full, "png") : file.meta.image

    let seed = file.frameOrder ?? Array(file.frames.keys)
    let filtered = (layer?.isEmpty == false) ? filterKeys(seed, forLayer: layer!) : seed
    let seeded = filtered.isEmpty ? seed : filtered

    let ordered: [String]
    if let override = options.keyOrdering {
      ordered = override(seeded)
    } else if file.frameOrder != nil {
      ordered = seeded
    } else {
      ordered = orderKeys(seeded, nil)
    }

    return .init(file: file, orderedKeys: ordered, atlasPath: atlasPath)
  }

  struct BuiltFrames {
    let frames: SpriteFrames
    let perFrameOffsets: [StringName: [Int: Vector2]]
    let defaultAnim: String?
  }

  static func buildFrames(_ decoded: AseDecoded, options: AseOptions) -> BuiltFrames {
    let file = decoded.file
    let keys = decoded.orderedKeys
    let atlas = ResourceLoader.load(path: decoded.atlasPath) as? Texture2D
    let frames = SpriteFrames()
    var offsetsByAnim: [StringName: [Int: Vector2]] = [:]

    let tags = file.meta.frameTags.filter { options.includeTags($0.name) }
    let chosenTags = tags.isEmpty
      ? [AseTag(name: "default", from: 0, to: max(0, keys.count - 1), direction: .forward)]
      : tags

    for tag in chosenTags {
      let animName = StringName(options.tagMap[tag.name] ?? tag.name)
      frames.addAnimation(anim: animName)
      frames.setAnimationLoop(anim: animName, loop: true)

      let indices = indicesFor(tag: tag)
      let delaysMs = indices.map { file.frames[keys[$0]]!.duration }
      let timing = pickTiming(delaysMs, options.timing)

      let fps: Double
      let frameDuration: (Int) -> Double

      switch timing {
      case let .uniform(fixed): fps = fixed
        frameDuration = { _ in 1.0 }
      case let .gcd(capped): fps = capped
        frameDuration = { ms in max(1.0, (Double(ms) * fps / 1000.0).rounded()) }
      case .exact: fps = 0
        frameDuration = { ms in Double(ms) / 1000.0 }
      }

      frames.setAnimationSpeed(anim: animName, fps: fps)

      var perAnimOffsets: [Int: Vector2] = [:]

      for (animFrameIndex, sourceIndex) in indices.enumerated() {
        let key = keys[sourceIndex]
        guard let f = file.frames[key] else { continue }

        let atlasTex = AtlasTexture()
        atlasTex.atlas = atlas
        atlasTex.region = Rect2(x: Float(f.frame.x), y: Float(f.frame.y), width: Float(f.frame.w), height: Float(f.frame.h))
        frames.addFrame(anim: animName, texture: atlasTex, duration: frameDuration(f.duration))

        if options.trimming == .applyPivotOrCenter, f.trimmed {
          if let off = offsetForTrimmed(frame: f, slices: file.meta.slices) {
            perAnimOffsets[animFrameIndex] = off
          }
        }
      }
      if !perAnimOffsets.isEmpty { offsetsByAnim[animName] = perAnimOffsets }
    }

    let first = chosenTags.first.map { options.tagMap[$0.name] ?? $0.name }
    return .init(frames: frames, perFrameOffsets: offsetsByAnim, defaultAnim: first)
  }
}

// MARK: - Timing helpers

private enum PickedTiming { case uniform(Double), gcd(Double), exact }

private func pickTiming(_ ms: [Int], _ mode: AseOptions.Timing) -> PickedTiming {
  switch mode {
  case let .uniformFPS(fps): return .uniform(fps)
  case .exactDelays: return .exact
  case let .delaysGCD(baseCap):
    let g = gcdArray(ms)
    let fps = min(baseCap, 1000.0 / Double(max(1, g)))
    return .gcd(fps)
  }
}

private func gcdArray(_ values: [Int]) -> Int {
  if values.isEmpty { return 1000 }
  return values.reduce(values[0]) { a, b in gcd(a, b) }
}

private func gcd(_ a: Int, _ b: Int) -> Int {
  var x = abs(a), y = abs(b)
  while y != 0 {
    let t = x % y
    x = y
    y = t
  }
  return x
}

// MARK: - Tags, directions, offsets

private func indicesFor(tag: AseTag) -> [Int] {
  let a = tag.from, b = tag.to
  switch tag.direction {
  case .forward: return a <= b ? Array(a ... b) : Array(stride(from: a, through: b, by: -1))
  case .reverse: return a <= b ? Array((a ... b).reversed()) : Array(stride(from: a, through: b, by: -1))
  case .pingpong:
    if a == b { return [a] }
    let forward = a <= b ? Array(a ... b) : Array(stride(from: a, through: b, by: -1))
    let back = Array(forward.dropLast().dropFirst().reversed())
    return forward + back
  }
}

private func offsetForTrimmed(frame: AseFrame, slices: [AseSlice]) -> Vector2? {
  let canvasW = Float(frame.sourceSize.w), canvasH = Float(frame.sourceSize.h)
  let pivot = pivotFor(frameIndex: nil, slices: slices) ?? Vector2(x: canvasW * 0.5, y: canvasH * 0.5)
  let spriteSource = frame.spriteSourceSize
  let ox = Float(spriteSource.x) - pivot.x + Float(frame.frame.w) * 0.5
  let oy = Float(spriteSource.y) - pivot.y + Float(frame.frame.h) * 0.5

  return Vector2(x: ox, y: oy)
}

private func pivotFor(frameIndex: Int?, slices: [AseSlice]) -> Vector2? {
  if let pivotSlice = slices.first(where: { $0.name == "pivot" }) {
    if let key = frameIndex
      .flatMap({ i in pivotSlice.keys.first(where: { $0.frame == i && $0.pivot != nil }) })
      ?? pivotSlice.keys.first(where: { $0.pivot != nil }),
      let p = key.pivot
    { return Vector2(x: Float(p.x), y: Float(p.y)) }
  }

  for slice in slices {
    if let key = frameIndex
      .flatMap({ i in slice.keys.first(where: { $0.frame == i && $0.pivot != nil }) })
      ?? slice.keys.first(where: { $0.pivot != nil }),
      let p = key.pivot
    {
      return Vector2(x: Float(p.x), y: Float(p.y))
    }
  }
  return nil
}

// MARK: - Key ordering + layer filter

private func orderKeys(_ keys: [String], _ override: (([String]) -> [String])?) -> [String] {
  if let override { return override(keys) }

  let parsed = keys.map { (key: $0, num: firstInt(in: $0)) }

  if parsed.allSatisfy({ $0.num != nil }) {
    return parsed.sorted {
      guard let a = $0.num, let b = $1.num else { return $0.key < $1.key }
      return a == b ? $0.key < $1.key : a < b
    }.map(\.key)
  }

  return keys.sorted()
}

private func firstInt(in s: String) -> Int? {
  var digits = ""

  for ch in s where ch.isNumber {
    digits.append(ch)
  }

  return digits.isEmpty ? nil : Int(digits)
}

private func extractLayerName(from filename: String) -> String? {
  guard let open = filename.lastIndex(of: "("), let close = filename[open...].firstIndex(of: ")") else { return nil }

  let raw = filename[filename.index(after: open) ..< close]
  let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

  return trimmed.isEmpty ? nil : trimmed
}

private func filterKeys(_ keys: [String], forLayer layer: String) -> [String] {
  let target = layer.lowercased()
  return keys.filter { extractLayerName(from: $0)?.lowercased() == target }
}

// MARK: - Path helpers

private func url(from path: String) -> URL {
  if let u = URL(string: path), u.scheme != nil { return u }
  return URL(fileURLWithPath: path)
}

private func string(from url: URL) -> String { url.isFileURL ? url.path : url.absoluteString }

private func withExtension(_ path: String, _ ext: String) -> String {
  let newURL = url(from: path).deletingPathExtension().appendingPathExtension(ext)
  return string(from: newURL)
}

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
    /// Ignore trimming metadata
    // no offsets are produced.
    case ignore
    /// Apply offsets so trimmed rectangles render as if placed back on the full canvas,
    /// using the `"pivot"` slice when present, otherwise any slice pivot, else canvas center.
    case applyPivotOrCenter
  }

  /// Predicate that selects which Aseprite *tags* become animations.
  ///
  /// The closure receives the tag name
  // return `true` to include it.
  /// Defaults to including all tags. If no tags pass this filter, a single
  /// `"default"` animation is synthesized that spans all frames.
  var includeTags: (String) -> Bool = { _ in true }

  /// Optional mapping from Aseprite tag names to animation names in Godot.
  ///
  /// Values override the emitted animation names
  // unlisted tags keep their original names.
  var tagMap: [String: String] = [:]

  /// Timing strategy applied when generating `SpriteFrames` animations.
  var timing: Timing = .delaysGCD()

  /// Trimming strategy used when producing optional per-frame offsets.
  var trimming: Trimming = .ignore

  /// Optional override for the ordering of frame dictionary keys.
  var keyOrdering: (([String]) -> [String])?

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

// MARK: - Aseprite JSON Model derived from version 1.3.15.2

@_documentation(visibility: private)
struct AseJson: Decodable {
  let frames: [String: AseFrame] // filename -> frame (unified)
  let meta: AseMeta
  let frameOrder: [String]? // preserves array order when present

  enum CodingKeys: String, CodingKey { case frames, meta }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)

    // { "frames": { "file 0.png": {...}, ... } }
    if let dict = try? c.decode([String: AseFrame].self, forKey: .frames) {
      frames = dict
      frameOrder = nil
      meta = try c.decode(AseMeta.self, forKey: .meta)
      return
    }

    // { "frames": [ { filename: "...", ... }, ... ] }
    let rows = try c.decode([AseFrameRow].self, forKey: .frames)
    var map: [String: AseFrame] = [:]
    map.reserveCapacity(rows.count)
    for r in rows {
      map[r.filename] = r.frameOnly
    }

    frames = map
    frameOrder = rows.map(\.filename)
    meta = try c.decode(AseMeta.self, forKey: .meta)
  }
}

// Helper to decode the array entries and convert to AseFrame
private struct AseFrameRow: Decodable {
  let filename: String
  let frame: AseRect
  let rotated: Bool
  let trimmed: Bool
  let spriteSourceSize: AseRect
  let sourceSize: AseSize
  let duration: Int

  var frameOnly: AseFrame {
    .init(frame: frame,
          rotated: rotated,
          trimmed: trimmed,
          spriteSourceSize: spriteSourceSize,
          sourceSize: sourceSize,
          duration: duration)
  }
}

struct AseFrame: Decodable {
  let frame: AseRect
  let rotated: Bool
  let trimmed: Bool
  let spriteSourceSize: AseRect
  let sourceSize: AseSize
  let duration: Int // ms
}

struct AseRect: Decodable {
  let x: Int
  let y: Int
  let w: Int
  let h: Int
}

struct AseSize: Decodable {
  let w: Int
  let h: Int
}

struct AseMeta: Decodable {
  let app: String
  let version: String
  let image: String
  let format: String?
  let size: AseSize
  let scale: String?
  let frameTags: [AseTag]
  let layers: [AseLayer]
  let slices: [AseSlice]
}

struct AseTag: Decodable {
  let name: String
  let from: Int
  let to: Int
  let direction: Direction

  enum Direction: String, Decodable { case forward, reverse, pingpong }
}

struct AseLayer: Decodable {
  let name: String
  let opacity: Int
  let blendMode: BlendMode

  enum BlendMode: String, Decodable {
    case normal, multiply, screen, overlay, darken, lighten, difference, exclusion
    case hue, saturation, color, luminosity, addition, subtract, divide
    case colorDodge = "color dodge", colorBurn = "color burn", hardLight = "hard light", softLight = "soft light"
  }
}

struct AseSlice: Decodable {
  let name: String
  let color: String?
  let keys: [AseSliceKey]
}

struct AseSliceKey: Decodable {
  let frame: Int
  let bounds: AseRect
  let center: AseRect?
  let pivot: AsePoint?
}

struct AsePoint: Decodable {
  let x: Int
  let y: Int
}
