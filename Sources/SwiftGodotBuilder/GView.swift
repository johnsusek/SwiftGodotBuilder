//
//  GView.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

// MARK: - Unified GView

/// The base protocol for all declarative Godot views.
///
/// `GView` is analogous to SwiftUI's `View`. It declares a `body`
/// (composite views) or provides a `makeNode` implementation (leaf views).
public protocol GView {
  /// The type of body this view returns. Defaults to `NeverGView` for leaves.
  associatedtype Body: GView = NeverGView

  /// A declarative body that describes the view’s content.
  var body: Body { get }

  /// Creates a concrete Godot `Node` from this view.
  func makeNode() -> Node
}

// Default: composites render via body, just like SwiftUI.
public extension GView {
  func makeNode() -> Node { body.makeNode() }
}

// Leaf default: leaves don't need to implement `body`,
// they automatically fall back to `NeverGView`.
public extension GView where Body == NeverGView {
  var body: NeverGView { NeverGView() }
}

/// A "never" view type used for leaves that have no body.
public struct NeverGView: GView {
  public func makeNode() -> Node {
    fatalError("NeverGView should never render")
  }
}

// MARK: - View Builders

/// A result builder that combines multiple `GView`s into one.
/// Used for `var body: some GView { ... }` style declarations.
@resultBuilder
public enum ViewBuilder {
  public static func buildBlock(_ parts: any GView...) -> any GView { GGroup(parts) }
  public static func buildOptional(_ part: (any GView)?) -> any GView { part ?? GGroup([]) }
  public static func buildEither(first: any GView) -> any GView { first }
  public static func buildEither(second: any GView) -> any GView { second }
  public static func buildExpression(_ v: any GView) -> any GView { v }
  public static func buildArray(_ parts: [any GView]) -> any GView { GGroup(parts) }
}

/// A result builder that collects arrays of `GView`s.
/// Used internally by node wrappers like `GNode`.
@resultBuilder
public enum NodeBuilder {
  public static func buildBlock(_ components: [any GView]...) -> [any GView] { components.flatMap { $0 } }
  public static func buildArray(_ components: [[any GView]]) -> [any GView] { components.flatMap { $0 } }
  public static func buildOptional(_ component: [any GView]?) -> [any GView] { component ?? [] }
  public static func buildEither(first: [any GView]) -> [any GView] { first }
  public static func buildEither(second: [any GView]) -> [any GView] { second }
  public static func buildExpression(_ expression: any GView) -> [any GView] { [expression] }
  public static func buildExpression(_ expression: [any GView]) -> [any GView] { expression }
}

// MARK: - Grouping

/// A lightweight container for multiple `GView`s.
///
/// Needed so `ViewBuilder` can return a single `GView` value
/// even when multiple children are provided. Internally this
/// either returns the child directly or wraps them in a `Node2D`.
public struct GGroup: GView {
  let children: [any GView]
  public init(_ children: [any GView]) { self.children = children }

  public func makeNode() -> Node {
    if children.count == 1 { return children[0].makeNode() }
    return GNode<Node2D>(nil) { children }.makeNode()
  }
}

// MARK: - Mapping

/// A higher-order view that transforms a node-producing `GView`.
///
/// This lets you apply modifiers (like `position`) declaratively,
/// without altering the base view directly.
public struct MapNode<V: GView, T: Node>: GView where V.Body == GNode<T> {
  let base: V
  let transform: (GNode<T>) -> GNode<T>
  public var body: some GView { transform(base.body) }
}
