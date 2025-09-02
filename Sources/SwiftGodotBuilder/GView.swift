//
//  GView.swift
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

/// A lightweight, SwiftUI-inspired protocol for declaratively describing
/// Godot node hierarchies in Swift.
///
/// Conformers model *views* that ultimately materialize into a Godot
/// `Node` via ``makeNode()``. Composition works similarly to SwiftUI:
/// a view either renders itself (a *leaf* view) or defers rendering to
/// its ``body`` (a *composite* view).
///
/// ### Leaf vs. Composite
/// - **Leaf**: Implement ``makeNode()`` and leave ``Body`` as the default
///   ``NeverGView``. Attempting to use `body` will trap.
/// - **Composite**: Provide a `body` made up of other `GView`s. The default
///   ``makeNode()`` forwards to `body.makeNode()`.
public protocol GView {
  /// The declarative content of this view.
  ///
  /// Defaults to ``NeverGView`` for leaf views. If you provide a concrete
  /// `Body`, the default ``makeNode()`` will delegate to `body.makeNode()`.
  associatedtype Body: GView = NeverGView

  /// The view’s body, used for composition.
  ///
  /// For leaf views (where `Body == NeverGView`) this property is provided
  /// by the protocol extension and traps if accessed.
  var body: Body { get }

  /// Materializes this view into a concrete Godot `Node`.
  ///
  /// - Returns: A fully constructed `Node` ready to be inserted in the tree.
  func makeNode() -> Node
}

public extension GView {
  /// Default implementation that delegates rendering to ``body``.
  ///
  /// Composite views typically rely on this; leaf views override it.
  ///
  /// - Returns: The node produced by `body.makeNode()`.
  func makeNode() -> Node {
    // Flush the registry in case any new custom classes were added in init
    GodotRegistry.flush()

    return body.makeNode()
  }
}

public extension GView where Body == NeverGView {
  /// Default `body` for leaf views.
  var body: NeverGView { NeverGView() }
}

/// A view used as the default `Body` for leaf `GView`s.
public struct NeverGView: GView {
  /// Traps unconditionally—`NeverGView` should never be rendered.
  public func makeNode() -> Node { fatalError("NeverGView should never render") }
}

/// A result builder that collects `GView` children for container nodes.
@resultBuilder
public enum NodeBuilder {
  /// Combines multiple child lists into a single flattened list.
  ///
  /// - Parameter c: Variadic groups of children.
  /// - Returns: A single flattened array of children.
  public static func buildBlock(_ c: [any GView]...) -> [any GView] { c.flatMap { $0 } }

  /// Flattens an array of child lists produced by loops/maps.
  ///
  /// - Parameter c: An array of child arrays.
  /// - Returns: A single flattened array of children.
  public static func buildArray(_ c: [[any GView]]) -> [any GView] { c.flatMap { $0 } }

  /// Passes through children when present, or yields an empty list.
  ///
  /// - Parameter c: Optional children.
  /// - Returns: `c` or `[]` if `nil`.
  public static func buildOptional(_ c: [any GView]?) -> [any GView] { c ?? [] }

  /// Chooses the `first` branch in `if/else` compositions.
  ///
  /// - Parameter first: Children from the first branch.
  /// - Returns: The provided children.
  public static func buildEither(first: [any GView]) -> [any GView] { first }

  /// Chooses the `second` branch in `if/else` compositions.
  ///
  /// - Parameter second: Children from the second branch.
  /// - Returns: The provided children.
  public static func buildEither(second: [any GView]) -> [any GView] { second }

  /// Lifts a single `GView` into a child list.
  ///
  /// - Parameter v: A child view.
  /// - Returns: A single-element child array.
  public static func buildExpression(_ v: any GView) -> [any GView] { [v] }

  /// Passes through an already-built child list (useful for `map`/loops).
  ///
  /// - Parameter v: A list of child views.
  /// - Returns: The same list.
  public static func buildExpression(_ v: [any GView]) -> [any GView] { v }
}
