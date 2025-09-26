import Foundation

/**
 # NodeApiGen

 Generates lightweight Swift aliases for Godot `Node` subclasses by reading
 `extension_api.json` (the official Godot API description) and emitting:

 ```swift
 public typealias Sprite2D$ = GNode<Sprite2D>
 public typealias Camera3D$ = GNode<Camera3D>
 // ...
  ```
 **/

/// Top-level container for the subset of Godot's API JSON we care about.
struct API: Decodable { let classes: [APIClass] }

/// Describes a single Godot class as declared in extension_api.json.
struct APIClass: Decodable {
  /// Class name (e.g. "Sprite2D").
  let name: String
  /// Optional base class name (e.g. "Node2D"). Empty or missing for roots.
  let inherits: String?
}

/// Describes a single Godot property entry from the API JSON.
struct APIProperty: Decodable {
  /// Property name (Godot style).
  let name: String
  /// Godot value type name (e.g. "String", "int", "Vector2").
  let type: String
  /// Setter method name when writable. Non-empty means writable.
  let setter: String?
  /// Getter method name (if present in API).
  let getter: String?
}

@inline(__always) func die(_ m: String) -> Never {
  fputs(m + "\n", stderr)
  exit(1)
}

let args = CommandLine.arguments
guard args.count >= 3 else { die("usage: NodeApiGen <extension_api.json> <out_aliases.swift>") }
let jsonURL = URL(fileURLWithPath: args[1])
let outAliases = URL(fileURLWithPath: args[2])

let data = try Data(contentsOf: jsonURL)
let api = try JSONDecoder().decode(API.self, from: data)

// Build parent map and lookup
let byName = Dictionary(uniqueKeysWithValues: api.classes.map { ($0.name, $0) })
let parent = [String: String](uniqueKeysWithValues: api.classes.compactMap { c in
  guard let p = c.inherits, !p.isEmpty else { return nil }
  return (c.name, p)
})

// Descends from Node
func isNodeDescendant(_ name: String) -> Bool {
  var cur: String? = name
  var seen = Set<String>()
  while let c = cur, !seen.contains(c) {
    if c == "Node" || parent[c] == "Node" { return true }
    seen.insert(c)
    cur = parent[c]
  }
  return false
}

let nodeKinds = api.classes.map(\.name).filter(isNodeDescendant).sorted()

// Godot -> SwiftGodot
let tmap: [String: String] = [
  "bool": "Bool",
  "int": "Int64",
  "float": "Double",
  "String": "String",
  "StringName": "StringName",
  "NodePath": "NodePath",
  "Vector2": "Vector2", "Vector2i": "Vector2i",
  "Vector3": "Vector3", "Vector3i": "Vector3i",
  "Vector4": "Vector4", "Vector4i": "Vector4i",
  "Quaternion": "Quaternion", "Basis": "Basis",
  "Transform2D": "Transform2D", "Transform3D": "Transform3D",
  "AABB": "AABB", "Rect2": "Rect2", "Rect2i": "Rect2i",
  "Color": "Color", "RID": "RID",
  "Callable": "Callable", "Signal": "Signal",
  "PackedByteArray": "PackedByteArray",
  "PackedInt32Array": "PackedInt32Array", "PackedInt64Array": "PackedInt64Array",
  "PackedFloat32Array": "PackedFloat32Array", "PackedFloat64Array": "PackedFloat64Array",
  "PackedStringArray": "PackedStringArray",
  "PackedVector2Array": "PackedVector2Array", "PackedVector3Array": "PackedVector3Array",
  "PackedColorArray": "PackedColorArray",
]

/// Produces a valid Swift identifier from an arbitrary string, quoting
/// Swift keywords with backticks and replacing illegal characters.
/// - Parameter raw: Source name to sanitize.
/// - Returns: A valid Swift identifier.
func swiftIdent(_ raw: String) -> String {
  let good = raw.replacingOccurrences(of: " ", with: "_")
    .replacingOccurrences(of: ":", with: "_")
    .replacingOccurrences(of: "-", with: "_")
  let keywords: Set<String> = [
    "repeat", "return", "switch", "default", "where", "in", "for", "while", "func",
    "class", "struct", "enum", "protocol", "deinit", "init", "let", "var", "typealias",
    "operator", "extension", "associatedtype", "if", "else", "case", "do", "as", "is",
    "try", "catch", "throws",
  ]
  return keywords.contains(good) ? "`\(good)`" : good
}

private func camelCase(_ s: String) -> String {
  if s.isEmpty { return s }
  var out = ""
  var uppercaseNext = false
  for ch in s {
    if ch == "_" || ch == "-" || ch == " " || ch == ":" {
      uppercaseNext = true
      continue
    }
    if out.isEmpty { out.append(String(ch).lowercased())
      continue
    }
    if uppercaseNext { out.append(String(ch).uppercased())
      uppercaseNext = false
    } else { out.append(ch) }
  }
  return out
}

// MARK: - Alias Emission

/// Writes public typealias <Name>$ = GNode<<Name>> for every class that
/// descends from Node, sorted alphabetically. The dollar suffix ($)
/// is used to avoid name collisions with the engine types while remaining terse.
/// Hidden from documentation so it doesn't clutter the doc site.

var aliasOut = """
// AUTO-GENERATED — do not edit.
// Generated from \(jsonURL.lastPathComponent) at \(ISO8601DateFormatter().string(from: .init()))
import SwiftGodot

"""

nodeKinds.forEach { aliasOut += "@_documentation(visibility: private) public typealias \($0)$ = GNode<\($0)>\n" }

let newData = Data(aliasOut.utf8)
if let old = try? Data(contentsOf: outAliases), old == newData {
  fputs("Aliases unchanged\n", stderr)
} else {
  try newData.write(to: outAliases, options: .atomic)
  print("Aliases: \(nodeKinds.count) types -> \(outAliases.path)")
}
