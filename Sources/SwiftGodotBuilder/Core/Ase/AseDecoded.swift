import Foundation
import SwiftGodot

/// Utilities for decoding Aseprite-exported JSON and resolving the associated
/// sprite atlas path.

// MARK: Decode + ordering

/// Result of decoding an Aseprite JSON file and resolving its atlas path.
///
struct AseDecoded {
  /// The parsed Aseprite file model.
  let file: AseFile
  /// Frame dictionary keys ordered deterministically for iteration/playback.
  let orderedKeys: [String]
  /// Resolved path (absolute URL string or filesystem path) to the image atlas.
  ///
  /// If `file.meta.image` is empty, this is computed by replacing the JSON
  /// extension with `.png`.
  let atlasPath: String
}

/// Errors specific to decoding/reading Aseprite artifacts.
private enum AseError: Error {
  /// The JSON text could not be read from `path`. The associated value is the path.
  case readFailed(String)
}

/// Decodes an Aseprite JSON file in either "Hash" or "Array" export formats.
///
/// - Note: Include Layers, Tags, and Slices in the Aseprite export settings.
///
/// - Example:
///   ```swift
///   let decoded = try decodeAse("res://player.json", options: .default)
///   for key in decoded.orderedKeys {
///     guard let frame = decoded.file.frames[key] else { continue }
///     // use frame.frame / duration / etc.
///   }
///   let texturePath = decoded.atlasPath
///   ```
func decodeAse(_ jsonPath: String, options: AseOptions) throws -> AseDecoded {
  let jsonText = FileAccess.getFileAsString(path: jsonPath)
  guard !jsonText.isEmpty else { throw AseError.readFailed(jsonPath) }

  let file = try JSONDecoder().decode(AseFile.self, from: Data(jsonText.utf8))

  let atlasPath = file.meta.image.isEmpty ? withExtension(jsonPath, "png") : file.meta.image

  let seed = file.frameOrder ?? Array(file.frames.keys)
  let ordered: [String]
  if let override = options.keyOrdering {
    ordered = override(seed)
  } else if file.frameOrder != nil {
    ordered = seed
  } else {
    ordered = orderKeys(seed, nil)
  }

  return .init(file: file, orderedKeys: ordered, atlasPath: atlasPath)
}

/// Computes an ordering for frame keys.
private func orderKeys(_ keys: [String], _ override: (([String]) -> [String])?) -> [String] {
  if let override { return override(keys) }

  let parsed = keys.map { (key: $0, n: firstInt(in: $0)) }

  if parsed.allSatisfy({ $0.n != nil }) {
    return parsed.sorted {
      guard let a = $0.n, let b = $1.n else { return $0.key < $1.key }
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

// MARK: Path utilities

@inline(__always) private func url(from path: String) -> URL {
  if let u = URL(string: path), u.scheme != nil { return u }
  return URL(fileURLWithPath: path)
}

@inline(__always) private func directoryURL(of path: String) -> URL {
  url(from: path).deletingLastPathComponent()
}

@inline(__always) private func string(from url: URL) -> String {
  url.isFileURL ? url.path : url.absoluteString
}

@inline(__always) private func withExtension(_ path: String, _ ext: String) -> String {
  let newURL = url(from: path).deletingPathExtension().appendingPathExtension(ext)
  return string(from: newURL)
}
