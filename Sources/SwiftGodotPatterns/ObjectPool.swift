import SwiftGodot

/// An optional pair of lifecycle hooks for pooled objects.
///
/// Types placed in an `ObjectPool` can conform to `PoolItem` to receive
/// hook calls during pooling:
/// - `onRelease()` is invoked **by the pool** whenever an object is returned
///   to the pool (and also right after creation to normalize the initial state).
/// - `onAcquire()` is a convenience hook you may choose to call yourself after
///   `acquire()` returns (this pool does **not** invoke it automatically).
///
/// Conformance is optional; default implementations are no-ops.
public protocol PoolItem: AnyObject {
  /// Prepare the object for active use (e.g., make visible, enable physics).
  func onAcquire()

  /// Reset the object for reuse (e.g., hide, stop motion, clear timers).
  func onRelease()
}

/// Default no-op hooks so conformance is opt-in and low-friction.
public extension PoolItem { func onAcquire() {}; func onRelease() {} }

/// An object pool for Godot `Object` subclasses (e.g., `Node`).
///
/// The pool can produce instances in two ways:
/// 1. From a `PackedScene` via `instantiate()`
/// 2. From a custom `factory` closure
///
/// You can supply either (or both). When both are present, `scene` is preferred.
/// New instances are normalized by calling `onRelease()` immediately after
/// creation so they enter the pool in a reset state.
///
/// ### Example
/// ```swift
/// final class Bullet: Node2D, PoolItem {
///   func onAcquire() { visible = true }
///   func onRelease() { visible = false; position = .zero }
/// }
///
/// let pool = ObjectPool<Bullet>(factory: { Bullet() })
/// pool.preload(64)
///
/// if let b = pool.acquire() {
///   b.onAcquire()
///   // configure and add to scene...
///   // later:
///   pool.release(b)
/// }
/// ```
public final class ObjectPool<T: Object> {
  /// Optional scene used to instantiate pooled instances.
  ///
  /// When non-`nil`, this is the preferred source of new objects.
  public var scene: PackedScene?

  /// Optional closure to create new instances when needed.
  ///
  /// Used when `scene` is `nil` or instantiation fails.
  public var factory: (() -> T)?

  /// Internal stack of idle, reusable instances.
  private var freeList: [T] = []

  /// Creates a pool.
  ///
  /// - Parameters:
  ///   - scene: Preferred source of new instances via `instantiate()`.
  ///   - factory: Fallback (or primary, if `scene` is `nil`) creator closure.
  public init(scene: PackedScene? = nil, factory: (() -> T)? = nil) {
    self.scene = scene; self.factory = factory
  }

  /// Eagerly creates and stores up to `count` instances.
  ///
  /// New instances (from `scene` or `factory`) are normalized by calling
  /// `onRelease()` before being placed in the pool.
  ///
  /// - Parameter count: Desired number of instances to prepare; negative values are treated as `0`.
  public func preload(_ count: Int) {
    for _ in 0 ..< max(0, count) {
      if let o = makeOne() { freeList.append(o) }
    }
  }

  /// Retrieves an instance from the pool or creates one on demand.
  ///
  /// Order of operations:
  /// 1. Return `freeList.popLast()` if available.
  /// 2. Otherwise attempt `scene.instantiate()` as `T`.
  /// 3. Otherwise use `factory` to create one.
  ///
  /// Note: This method does **not** call `onAcquire()`; call it yourself if
  /// your type uses that hook.
  ///
  /// - Returns: A reusable instance, or `nil` if neither `scene` nor `factory` can produce one.
  public func acquire() -> T? { freeList.popLast() ?? makeOne() }

  /// Returns an instance to the pool for reuse.
  ///
  /// Calls `onRelease()` on `PoolItem` conformers, then appends to the free list.
  ///
  /// - Parameter o: The instance to recycle.
  public func release(_ o: T) {
    (o as? PoolItem)?.onRelease()
    freeList.append(o)
  }

  /// Creates a single instance from `scene` or `factory`, normalized via `onRelease()`.
  ///
  /// - Returns: A new instance ready to be pooled, or `nil` if creation failed.
  private func makeOne() -> T? {
    if let s = scene, let o = s.instantiate() as? T { (o as? PoolItem)?.onRelease(); return o }
    if let f = factory { let o = f(); (o as? PoolItem)?.onRelease(); return o }
    return nil
  }
}
