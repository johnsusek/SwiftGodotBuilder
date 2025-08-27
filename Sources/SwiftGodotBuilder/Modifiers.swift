//
//  Modifiers.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

// MARK: - Core GNode Modifiers

public extension GNode {
  /// Applies a value to the node using a reference-writable key path.
  ///
  /// This queues the change and returns a **new** `GNode` (value semantics),
  /// so you can fluently chain modifiers before realization.
  func set<V>(_ keyPath: ReferenceWritableKeyPath<T, V>, _ value: V) -> Self {
    var c = self
    c.ops.append { n, _ in n[keyPath: keyPath] = value }
    return c
  }

  /// Runs an arbitrary configuration block on the concrete node.
  ///
  /// Prefer `set(_:_: )` for simple property assignment; use `configure(_:)`
  /// for imperative tweaks that don’t fit key-path assignment.
  func configure(_ body: @escaping (T) -> Void) -> Self {
    var c = self
    c.ops.append { n, _ in body(n) }
    return c
  }
}

// MARK: - Convenience Init

public extension GNode where T: Node {
  /// Convenience initializer that infers the factory for default-constructible nodes.
  ///
  /// - Parameters:
  ///   - name: Optional node name (appears in the scene tree).
  ///   - children: Declarative children (built later during realization).
  init(_ name: String? = nil, @NodeBuilder _ children: () -> [any GView] = { [] }) {
    self.init(name, children: children, factory: { T() })
  }
}

// MARK: - CanvasItem Modifiers

public extension GNode where T: CanvasItem {
  /// Multiplies the render color of the node. (Premultiplies alpha.)
  func modulate(r: Double, g: Double, b: Double, a: Double) -> Self {
    set(\.modulate, Color(r: Float(r), g: Float(g), b: Float(b), a: Float(a)))
  }

  /// Multiplies the render color of the node. (Premultiplies alpha.)
  func modulate(_ c: Color) -> Self { set(\.modulate, c) }

  /// Z-order within the same canvas layer.
  func zIndex(_ z: Int32) -> Self { set(\.zIndex, z) }

  /// Controls visibility.
  func visible(_ v: Bool) -> Self { set(\.visible, v) }
}

// MARK: - Node2D Modifiers

public extension GNode where T: Node2D {
  /// Sets position using doubles (convenience overload).
  func position(x: Double, y: Double) -> Self {
    set(\.position, Vector2(x: Float(x), y: Float(y)))
  }

  /// Sets position with a `Vector2`.
  func position(_ p: Vector2) -> Self { set(\.position, p) }

  /// Rotation in radians.
  func rotation(_ r: Double) -> Self { set(\.rotation, r) }

  /// Non-uniform scale.
  func scale(_ s: Vector2) -> Self { set(\.scale, s) }

  /// Shear/Skew factor (radians).
  func skew(_ s: Double) -> Self { set(\.skew, s) }

  /// Full 2D transform.
  func transform(_ t: Transform2D) -> Self { set(\.transform, t) }
}

// MARK: - Camera2D Modifiers

public extension GNode where T: Camera2D {
  /// Sets camera offset using doubles (convenience overload).
  func offset(x: Double, y: Double) -> Self {
    set(\.offset, Vector2(x: Float(x), y: Float(y)))
  }

  /// Sets camera offset with a `Vector2`.
  func offset(_ p: Vector2) -> Self { set(\.offset, p) }

  /// Zoom factor (1 = no zoom). Use values > 1 to zoom out.
  func zoom(_ z: Vector2) -> Self { set(\.zoom, z) }
}

// MARK: - Sprite2D Modifiers

public extension GNode where T: Sprite2D {
  /// Loads and sets a texture from `res://{path}` using the shared `Assets` cache.
  ///
  /// - Note: `path` should be relative (e.g. `"ball.png"`). The modifier prefixes `res://`.
  ///         If the resource can’t be loaded, a warning is printed.
  func texture(_ path: String) -> Self {
    var c = self
    c.ops.append { n, ctx in
      let resPath = "res://" + path
      if let tex = ctx.assets.texture(path: resPath) {
        n.texture = tex
      } else {
        GD.print("⚠️ Failed to load texture:", resPath)
      }
    }
    return c
  }

  /// Horizontal flip.
  func flipH(_ flip: Bool) -> Self { set(\.flipH, flip) }

  /// Vertical flip.
  func flipV(_ flip: Bool) -> Self { set(\.flipV, flip) }

  /// Animation frame index.
  func frame(_ f: Int) -> Self { set(\.frame, Int32(f)) }
}

// MARK: - CollisionShape2D Modifiers

public extension GNode where T: CollisionShape2D {
  /// Sets the collision shape to a `RectangleShape2D`.
  func shape(_ shape: RectangleShape2D) -> Self { set(\.shape, shape) }
}

// MARK: - ColorRect Modifiers

public extension GNode where T: ColorRect {
  /// Fills the rectangle with a constant color.
  func color(_ c: Color) -> Self { set(\.color, c) }
}

// MARK: - Label Modifiers

public extension GNode where T: Label {
  /// Sets the label text.
  func text(_ s: String) -> Self { set(\.text, s) }
}

// MARK: - Button Modifiers

public extension GNode where T: Button {
  /// Sets the button title.
  func text(_ s: String) -> Self { set(\.text, s) }
}

// MARK: - GView Modifiers (Node2D-specialized)

public extension GView where Body == GNode<Node2D> {
  /// View-level convenience for `Node2D.position(_:)`.
  ///
  /// Lets you write:
  /// ```
  /// MyNode2DView().position(Vector2(x: 100, y: 50))
  /// ```
  /// without reaching into `body`.
  func position(_ p: Vector2) -> some GView { MapNode(base: self) { $0.position(p) } }
}
