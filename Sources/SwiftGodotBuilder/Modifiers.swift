//
//  Modifiers.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

public extension GNode where T: Sprite2D {
  /// Loads and sets a texture from `res://{path}`.
  ///
  /// - Note: Do not include `res://`.
  func texture(_ path: String) -> Self {
    var c = self
    c.ops.append { n in
      guard let resource = ResourceLoader.load(path: "res://" + path) as? Texture2D else {
        GD.print("⚠️ Failed to load texture:", path)
        return
      }
      n.texture = resource
    }
    return c
  }
}
