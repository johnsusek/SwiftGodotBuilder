import Foundation
import SwiftGodot

// Marker for views that need to bind refs into the eventual root.
protocol _RefBindTag {
  func _makeAndBind(into root: Node) -> Node
}

struct _BindWeakRef<Root: Node, U: Node>: GView, _RefBindTag {
  let inner: any GView
  let kp: ReferenceWritableKeyPath<Root, U?>

  func toNode() -> Node { inner.toNode() }

  func _makeAndBind(into host: Node) -> Node {
    let built = inner.toNode()

    // Fast path: the host being built is already the Root
    if let owner = host as? Root, let child = built as? U {
      owner[keyPath: kp] = child
      return built
    }

    // Fallback: we were nested; bind on next frame once the tree is complete
    _ = Engine.onNextFrame {
      guard let owner = _findAncestor(startingAt: built, as: Root.self),
            let child = built as? U else { return }
      owner[keyPath: kp] = child
    }
    return built
  }
}

struct _BindWeakRefs<Root: Node, U: Node>: GView, _RefBindTag {
  let inner: any GView
  let kp: ReferenceWritableKeyPath<Root, NSHashTable<U>>

  func toNode() -> Node { inner.toNode() }

  func _makeAndBind(into host: Node) -> Node {
    let built = inner.toNode()

    if let owner = host as? Root, let child = built as? U {
      owner[keyPath: kp].add(child)
      return built
    }

    _ = Engine.onNextFrame {
      guard let owner = _findAncestor(startingAt: built, as: Root.self),
            let child = built as? U else { return }
      owner[keyPath: kp].add(child)
    }
    return built
  }
}

// Defer binding for nested children until after they're parented.
private func _findAncestor<Root: Node>(startingAt node: Node, as _: Root.Type) -> Root? {
  var cur = node.getParent()
  while let p = cur {
    if let r = p as? Root { return r }
    cur = p.getParent()
  }
  return nil
}

// MARK: - Public builder API

public extension GNode {
  /// Bind the created node into a `weak` optional property on an ancestor `Root`.
  /// Usage:
  ///   final class Player: Node { public weak var gun: Gun? }
  ///   GNode<Gun>().ref(\Player.gun)
  func ref<Root: Node>(_ kp: ReferenceWritableKeyPath<Root, T?>) -> any GView {
    _BindWeakRef(inner: self, kp: kp)
  }

  /// Bind the created node into an `NSHashTable<T>` on an ancestor `Root`.
  /// Usage:
  ///   final class Spawner: Node { public let bullets = NSHashTable<Bullet>.weakObjects() }
  ///   GNode<Bullet>().ref(into: \Spawner.bullets)
  func ref<Root: Node>(into kp: ReferenceWritableKeyPath<Root, NSHashTable<T>>) -> any GView {
    _BindWeakRefs(inner: self, kp: kp)
  }
}
