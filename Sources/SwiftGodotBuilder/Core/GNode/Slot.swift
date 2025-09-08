import SwiftGodot

/// A weak, typed outlet you can fill at build-time.
///
/// Use with ``GNode/slot(_:)`` to bind a child node to a property on the root.
/// Example:
///
/// ```swift
/// class Player: Node2D {
///   let sprite = Slot<Sprite2D>()
/// }
///
/// let player = GNode<Player>("Player") {
///   Sprite2D$()
///     .res(\.texture, "player.png")
///     .slot(\.sprite) // binds to Player.sprite
/// }
/// ```
///
public final class Slot<T: Node> {
  public weak var node: T?
  public init() {}
}

/// A private protocol to mark slot-binding views.
protocol _SlotTag {
  func _makeAndBind(into root: Node) -> Node
}

/// A view wrapper that binds its inner node to a slot on the root.
struct _Slot<Root: Node, U: Node>: GView, _SlotTag {
  let inner: any GView
  let kp: KeyPath<Root, Slot<U>>

  func toNode() -> Node { inner.toNode() }

  /// Builds the inner node and binds it to the slot on the root if types align.
  func _makeAndBind(into root: Node) -> Node {
    // build the child
    let built = inner.toNode()
    // bind to the slot if types line up
    if let r = root as? Root, let u = built as? U {
      r[keyPath: kp].node = u
    }
    return built
  }
}
