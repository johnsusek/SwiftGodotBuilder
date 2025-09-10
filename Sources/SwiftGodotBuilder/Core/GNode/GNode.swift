//
//  GNode.swift
//
//  Created by John Susek on 08/26/2025.
//
import Foundation
import SwiftGodot

/// A generic, SwiftUI-style node builder that materializes a concrete Godot `Node`.
///
/// `GNode` is the primary "leaf/container" building block in the declarative API.
///
/// ### Examples
/// **A simple sprite with a name and position:**
/// ```swift
/// let player = GNode<Node2D>("Player") {
///   Sprite2D$()
///     .res(\.texture, "player.png")
///     .position(Vector2(x: 48, y: 64))
/// }
/// .position(Vector2(x: 100, y: 200))
/// ```
///
/// **Supplying a custom `make` fn (e.g., subclass instance that you can configure):**
/// ```swift
/// let hud = GNode<CustomHUD>("HUD", make: { CustomHUD("Top", "Player1") }) {
///   HealthBar()
///   ScoreLabel()
/// }
/// ```
///
/// **Configuring with an arbitrary closure:**
/// ```swift
/// let area = GNode<ColorRect>("Redzone")
///             .configure { $0.setSize(Vector2(x: 100.0, y: 100.0)) }
/// ```
@dynamicMemberLookup
public struct GNode<T: Node>: GView {
  /// A queued operation applied to the node after construction but before children mount.
  public typealias Op = (T) -> Void
  /// Name for the node (`Node.name`).
  private let name: String?
  /// Declarative children to mount under this node.
  private let children: [any GView]
  /// Make fn that constructs the concrete node of type `T`.
  private let make: () -> T
  /// Accumulated configuration operations (builder modifiers).
  var ops: [Op] = []

  /// Creates a node with a name, declarative children, and a custom `make` fn.
  ///
  /// - Parameters:
  ///   - name: Optional node name (assigned to `Node.name`).
  ///   - children: A `NodeBuilder` block producing child views.
  ///   - make: Closure that constructs the concrete `T` instance.
  public init(_ name: String? = UUID().uuidString,
              @NodeBuilder _ children: () -> [any GView] = { [] },
              make: @escaping () -> T)
  {
    self.name = name
    self.children = children()
    self.make = make
  }

  /// Creates a node with a name and declarative children, using `T()` as the make.
  ///
  /// - Parameters:
  ///   - name: Optional node name (assigned to `Node.name`).
  ///   - children: A `NodeBuilder` block producing child views.
  public init(_ name: String = UUID().uuidString,
              @NodeBuilder _ children: () -> [any GView] = { [] })
  {
    self.init(name, children, make: { T() })
  }
}

// MARK: Core

public extension GNode {
  /// Materializes the node, applies all queued operations, and mounts children.
  ///
  /// - Returns: The fully configured node as `Node`.
  func toNode() -> Node {
    let n = make()
    if let name { n.name = StringName(name) }
    ops.forEach { $0(n) }

    for view in children {
      if let binder = view as? _RefBindTag {
        let child = binder._makeAndBind(into: n)
        n.addChild(node: child)
      } else {
        n.addChild(node: view.toNode())
      }
    }

    return n
  }

  /// Appends an arbitrary configuration operation.
  ///
  /// Use this for complex logic that doesn't map cleanly to a single key path.
  ///
  /// - Parameter f: A closure receiving the freshly constructed `T` to mutate.
  /// - Returns: A new `GNode` with the operation appended.
  func configure(_ f: @escaping (T) -> Void) -> Self {
    var s = self
    s.ops.append(f)
    return s
  }

  /// Queues a property assignment on the node using a writable key path.
  ///
  /// - Parameters:
  ///   - kp: Writable key path to a property on `T`.
  ///   - v: The value to assign.
  /// - Returns: A new `GNode` with the operation appended.
  @discardableResult
  private func set<V>(_ kp: ReferenceWritableKeyPath<T, V>, _ v: V) -> Self {
    var s = self
    s.ops.append { $0[keyPath: kp] = v }
    return s
  }

  /// Dynamic-member setter for any writable property via key path.
  ///
  /// Enables fluent modifiers like `.position(Vector2(x: 0, y: 0))`.
  ///
  /// - Parameter kp: Writable key path on `T`.
  /// - Returns: A closure taking the value to set and returning a new `GNode`.
  subscript<V>(dynamicMember kp: ReferenceWritableKeyPath<T, V>) -> (V) -> Self { { v in set(kp, v) } }

  /// Dynamic-member convenience for `StringName` properties.
  ///
  /// Allows passing a `String` where the underlying property is `StringName`
  /// (e.g., `.name("Player")`).
  ///
  /// - Parameter kp: Writable key path on `T` whose value is `StringName`.
  /// - Returns: A closure taking `String` and returning a new `GNode`.
  subscript(dynamicMember kp: ReferenceWritableKeyPath<T, StringName>) -> (String) -> Self { { s in set(kp, StringName(s)) } }

  /// Dynamic-member convenience for `RawRepresentable` properties.
  ///
  /// Useful for enum-backed settings that use integer or string raw values
  /// (e.g., `.processMode(.always)`).
  ///
  /// - Parameter kp: Writable key path on `T` whose value conforms to `RawRepresentable`.
  /// - Returns: A closure taking the enum's `RawValue` and returning a new `GNode`.
  subscript<E>(dynamicMember kp: ReferenceWritableKeyPath<T, E>) -> (E.RawValue) -> Self where E: RawRepresentable { { raw in
    guard let e = E(rawValue: raw) else {
      GD.print("⚠️ Invalid rawValue for \(E.self):", raw)
      return self
    }

    return set(kp, e)
  } }
}

public extension GNode {
  /// Grouping operations for `GNode` instances.
  func group(_ name: StringName, persistent: Bool = false) -> Self {
    var s = self
    s.ops.append { $0.addToGroup(name, persistent: persistent) }
    return s
  }

  /// Adds this node to a group.
  func group(_ name: String, persistent: Bool = false) -> Self {
    group(StringName(name), persistent: persistent)
  }

  /// Adds this node to multiple groups.
  func groups<S: Sequence>(_ names: S, persistent: Bool = false) -> Self where S.Element == StringName {
    var s = self
    s.ops.append { n in for g in names {
      n.addToGroup(g, persistent: persistent)
    } }
    return s
  }

  /// Instantiates a PackedScene and attaches it as a child.
  ///
  /// Example:
  /// ```swift
  /// Node2D$().instanceScene("scenes/enemy.tscn")
  /// ```
  func instanceScene(_ path: String, configure: ((Node) -> Void)? = nil) -> Self {
    withResource(path, as: PackedScene.self) { host, scene in
      guard let child = scene.instantiate() else { return }
      configure?(child)
      host.addChild(node: child)
    }
  }
}
