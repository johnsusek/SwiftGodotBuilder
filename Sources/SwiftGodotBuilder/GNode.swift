//
//  GNode.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

/// A generic wrapper that adapts a Godot `Node` type into a SwiftUI-like `GView`.
///
/// `GNode` allows you to declaratively describe a Godot scene tree in Swift,
/// while still giving you access to the underlying node for configuration.
/// It captures a list of "ops" (configuration operations) and child views,
/// then builds the corresponding Godot `Node` when `makeNode` is called.
///
/// Example:
/// ```swift
/// let scene = GNode<Node2D>("Root") {
///   GNode<Sprite2D>("Ball") {
///     // child views...
///   }
/// }
/// ```
public struct GNode<T: Node>: GView {
  /// A configuration closure that mutates the node after creation.
  public typealias Op = (_ node: T, _ ctx: BuildContext) -> Void

  /// Optional node name. Will be applied to the created Godot node.
  private let name: String?

  /// Child views (subnodes) declared in this node’s body.
  private let children: [any GView]

  /// Factory for instantiating the underlying Godot node type.
  private let factory: () -> T

  /// List of operations to apply to the node after creation.
  var ops: [Op] = []

  /// Creates a new `GNode`.
  ///
  /// - Parameters:
  ///   - name: Optional name for the node in the scene tree.
  ///   - children: A builder for this node’s children, using the `@NodeBuilder` result builder.
  ///   - factory: A closure that constructs the underlying Godot node type.
  public init(
    _ name: String? = nil,
    @NodeBuilder children: () -> [any GView] = { [] },
    factory: @escaping () -> T
  ) {
    self.name = name
    self.children = children()
    self.factory = factory
  }

  /// Constructs the actual Godot node and applies all ops and children.
  ///
  /// - Parameter ctx: The `BuildContext` containing resources and environment info.
  /// - Returns: A fully configured Godot `Node` with its children attached.
  public func makeNode(ctx: BuildContext) -> Node {
    let node = factory()
    if let name { node.name = StringName(name) }
    ops.forEach { $0(node, ctx) }
    for child in children {
      let childNode = child.makeNode(ctx: ctx)
      node.addChild(node: childNode)
    }
    return node
  }
}
