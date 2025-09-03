import SwiftGodot

/// A weak, typed reference to a live Godot `Node`.
///
/// `Ref` holds a `weak` pointer to a node of type `T`. The reference
/// automatically becomes `nil` when the node is freed/dies, making it safe to
/// cache outlets from declarative builders without creating retain cycles.
///
/// ```swift
/// let label = Ref<Label>()
///
/// Label$()
///   .text("Lives: 3")
///   .outlet(label)
///
/// // Later: update immediately if safe
/// _ = label.node?.text = "Lives: 4"
/// ```
public final class Ref<T: Node> {
  /// The underlying weak node reference. Becomes `nil` when the node is freed.
  public weak var node: T?

  /// Creates an empty `Ref`.
  public init() {}
}

/// A weak, batched collector for many nodes of the same type (e.g. rows, bullets).
///
/// `Refs` stores multiple weak references and exposes a computed `alive`
/// array that filters out freed nodes. Use from ``GNode/ref(into:)`` to
/// capture many instances during scene construction.
///
/// ```swift
/// let bullets = Refs<Area2D>()
///
/// ForEach(0..<N) { _ in
///   Area2D$()
///     .ref(info: bullets)
/// }
///
/// // Later:
/// for b in bullets.alive { _ = b.queueFree() }
/// ```
public final class Refs<T: Node> {
  /// Internal weak container for `T`.
  @_documentation(visibility: private)
  public struct WeakBox { public weak var value: T? }

  /// The weakly-held items (may contain `nil` values over time).
  public private(set) var items: [WeakBox] = []

  /// Creates an empty `Refs`.
  public init() {}

  /// Snapshot of currently alive nodes.
  @inlinable public var alive: [T] { items.compactMap(\.value) }

  /// Adds a node to the collection (used by ``GNode/ref(into:)``).
  public func add(_ n: T) { items.append(.init(value: n)) }
}

public extension GNode {
  /// Connects the created node to a ``Ref`` outlet during build.
  ///
  /// - Parameter r: The outlet to receive the created node.
  /// - Returns: A copy of `Self` with the outlet operation appended.
  func ref(_ r: Ref<T>) -> Self {
    var s = self
    s.ops.append { n in r.node = n }
    return s
  }

  /// Adds the created node to a ``Refs`` collector during build.
  ///
  /// - Parameter r: The collector to receive the created node.
  /// - Returns: A copy of `Self` with the collect operation appended.
  func ref(into r: Refs<T>) -> Self {
    var s = self
    s.ops.append { n in r.add(n) }
    return s
  }
}
