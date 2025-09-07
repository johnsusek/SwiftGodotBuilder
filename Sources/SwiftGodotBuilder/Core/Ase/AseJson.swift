import Foundation
import SwiftGodot

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
