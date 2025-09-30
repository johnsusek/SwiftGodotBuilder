//
//  GNode+Res.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

@inline(__always) private func resPath(_ p: String) -> String { p.hasPrefix("res://") ? p : "res://" + p }

@inline(__always)
private func loadRes<R: Resource>(_ path: String, _: R.Type = R.self) -> R? {
  guard let r = ResourceLoader.load(path: resPath(path)) as? R else {
    GD.print("⚠️ Failed to load \(R.self):", path)
    return nil
  }
  return r
}

public extension GNode {
  // Assign to optional Resource properties.
  func res<R: Resource>(_ kp: ReferenceWritableKeyPath<T, R?>, _ path: String) -> Self {
    var s = self
    s.ops.append { n in
      n[keyPath: kp] = loadRes(path, R.self)
    }
    return s
  }

  // Assign to non-optional Resource properties.
  func res<R: Resource>(_ kp: ReferenceWritableKeyPath<T, R>, _ path: String) -> Self {
    var s = self
    s.ops.append { n in
      if let r: R = loadRes(path, R.self) { n[keyPath: kp] = r } else { GD.print("⚠️", R.self, "nil for", path) }
    }
    return s
  }

  // Conditional convenience (skip on nil path).
  func resIf<R: Resource>(_ kp: ReferenceWritableKeyPath<T, R?>, _ path: String?) -> Self {
    guard let path else { return self }
    return res(kp, path)
  }

  // Fully generic "load then apply" hook for special cases (e.g. PackedScene instancing, Shader -> ShaderMaterial).
  func withResource<R: Resource>(_ path: String, as _: R.Type = R.self, apply: @escaping (T, R) -> Void) -> Self {
    var s = self
    s.ops.append { n in
      guard let r: R = loadRes(path, R.self) else { return }
      apply(n, r)
    }
    return s
  }
}
