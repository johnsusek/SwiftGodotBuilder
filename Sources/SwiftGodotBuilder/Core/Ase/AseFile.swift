import Foundation
import SwiftGodot

// MARK: - Aseprite JSON Model

public struct AseFile: Decodable {
  public let frames: [String: AseFrame] // filename -> frame (unified)
  public let meta: AseMeta
  public let frameOrder: [String]? // preserves array order when present

  enum CodingKeys: String, CodingKey { case frames, meta }

  public init(from decoder: Decoder) throws {
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

public struct AseFrame: Decodable {
  public let frame: AseRect
  public let rotated: Bool
  public let trimmed: Bool
  public let spriteSourceSize: AseRect
  public let sourceSize: AseSize
  public let duration: Int // ms
}

public struct AseRect: Decodable {
  public let x: Int
  public let y: Int
  public let w: Int
  public let h: Int
}

public struct AseSize: Decodable {
  public let w: Int
  public let h: Int
}

public struct AseMeta: Decodable {
  public let app: String
  public let version: String
  public let image: String
  public let format: String?
  public let size: AseSize
  public let scale: String?
  public let frameTags: [AseTag]
  public let layers: [AseLayer]
  public let slices: [AseSlice]
}

public struct AseTag: Decodable {
  public let name: String
  public let from: Int
  public let to: Int
  public let direction: Direction

  public enum Direction: String, Decodable { case forward, reverse, pingpong }
}

public struct AseLayer: Decodable {
  public let name: String
  public let opacity: Int
  public let blendMode: BlendMode

  public enum BlendMode: String, Decodable {
    case normal, multiply, screen, overlay, darken, lighten, difference, exclusion
    case hue, saturation, color, luminosity, addition, subtract, divide
    case colorDodge = "color dodge", colorBurn = "color burn", hardLight = "hard light", softLight = "soft light"
  }
}

public struct AseSlice: Decodable {
  public let name: String
  public let color: String?
  public let keys: [AseSliceKey]
}

public struct AseSliceKey: Decodable {
  public let frame: Int
  public let bounds: AseRect
  public let center: AseRect?
  public let pivot: AsePoint?
}

public struct AsePoint: Decodable {
  public let x: Int
  public let y: Int
}
