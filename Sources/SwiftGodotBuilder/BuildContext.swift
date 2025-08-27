//
//  BuildContext.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

// MARK: - BuildContext

/// Per-build environment passed down the tree during realization.
/// Currently just wraps shared `Assets` (texture cache), but can grow
/// to include theme, localization, physics handles, etc.
public struct BuildContext {
  public let assets: Assets
  public init(assets: Assets) { self.assets = assets }
}

// MARK: - Assets

/// Lightweight asset cache for Godot resources used by views.
public final class Assets {
  private var textures: [String: Texture2D] = [:]

  public init() {}

  /// Loads (and memoizes) a `Texture2D` at `path`.
  ///
  /// - Parameter path: A Godot resource path, e.g. `"res://sprites/ball.png"`.
  /// - Returns: The loaded `Texture2D` or `nil` if not found or wrong type.
  ///
  /// - First call hits `ResourceLoader`; subsequent calls return the cached instance.
  public func texture(path: String) -> Texture2D? {
    if let t = textures[path] { return t }
    guard let resource = ResourceLoader.load(path: path) as? Texture2D else { return nil }
    textures[path] = resource
    return resource
  }
}
