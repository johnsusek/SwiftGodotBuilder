import SwiftGodot
import SwiftGodotPatterns

/// A Godot node that bridges an `EventBus` into the scene,
/// and relays payloads to registered receivers.
@Godot
public final class GEventRelay: Node {
  /// The type-erased event bus to subscribe to.
  ///
  /// Set this before the node enters the tree; if `nil` at `_ready`, no subscription
  /// is created. You can build an instance via ``AnyEventBus`` or
  /// ``ServiceLocator/anyBus(_:)``.
  public var bus: AnyEventBus?

  /// Per-event receivers: `(weak node, callback)`.
  ///
  /// The callback receives each payload as `Any`. Downcast to your concrete type inside.
  /// Dead nodes (`weak` value is `nil`) are skipped at dispatch time.
  var each: [(Weak<Node>, (Any) -> Void)] = []

  /// Batch receivers: `(weak node, callback)`.
  ///
  /// The callback receives the full batch as `[Any]`. Downcast or map as needed.
  /// Dead nodes are skipped at dispatch time.
  var batch: [(Weak<Node>, ([Any]) -> Void)] = []

  /// Opaque tokens returned by the bus, used to cancel on exit.
  private var tokEach: Any?
  private var tokBatch: Any?

  /// Godot lifecycle hook: subscribes to the bus, if present.
  ///
  /// Subscriptions are captured weakly to avoid retaining the relay.
  override public func _ready() {
    guard let bus else { return }
    tokEach = bus.onEach { [weak self] any in self?.routeEach(any) }
    tokBatch = bus.onBatch { [weak self] arr in self?.routeBatch(arr) }
  }

  /// Godot lifecycle hook: cancels subscriptions and clears receiver lists.
  override public func _exitTree() {
    if let bus, let t = tokEach { bus.cancel(t) }
    if let bus, let t = tokBatch { bus.cancel(t) }
    tokEach = nil
    tokBatch = nil
    each.removeAll()
    batch.removeAll()
  }

  /// Forwards a single payload to all live per-event receivers.
  ///
  /// - Parameter any: The type-erased event payload.
  private func routeEach(_ any: Any) {
    for (weakNode, call) in each {
      guard weakNode.value != nil else { continue }
      call(any)
    }
  }

  /// Forwards a batch of payloads to all live batch receivers.
  ///
  /// - Parameter arr: The type-erased batch of event payloads.
  private func routeBatch(_ arr: [Any]) {
    for (weakNode, call) in batch {
      guard weakNode.value != nil else { continue }
      call(arr)
    }
  }
}

/// Type-erased facade over `EventBus<E>`.
///
/// `AnyEventBus` hides the concrete `Event` type, exposing:
/// - ``onEach(_:)`` delivering `Any` payloads,
/// - ``onBatch(_:)`` delivering `[Any]`,
/// - ``cancel(_:)`` accepting the opaque token returned by registration.
///
/// Tokens are stored as `Any` but are still the underlying `EventBus<E>.Token`.
public struct AnyEventBus {
  private let _onEach: (@escaping (Any) -> Void) -> Any
  private let _onBatch: (@escaping ([Any]) -> Void) -> Any
  private let _cancel: (Any) -> Void

  /// Wraps a concrete `EventBus<E>` into a type-erased bus.
  /// - Parameter bus: The strongly typed bus to wrap.
  public init<E>(_ bus: EventBus<E>) {
    _onEach = { h in bus.onEach { h($0) } }
    _onBatch = { h in bus.onBatch { h($0) } }
    _cancel = { tok in if let t = tok as? EventBus<E>.Token { bus.cancel(t) } }
  }

  /// Registers a per-event subscriber receiving type-erased payloads.
  /// - Parameter f: Callback invoked synchronously on the publisher's thread.
  /// - Returns: An opaque token to pass back to ``cancel(_:)``.
  @discardableResult public func onEach(_ f: @escaping (Any) -> Void) -> Any { _onEach(f) }

  /// Registers a batch subscriber receiving type-erased payload arrays.
  /// - Parameter f: Callback invoked once per batch publish.
  /// - Returns: An opaque token to pass back to ``cancel(_:)``.
  @discardableResult public func onBatch(_ f: @escaping ([Any]) -> Void) -> Any { _onBatch(f) }

  /// Cancels a prior subscription created by ``onEach(_:)`` or ``onBatch(_:)``.
  /// - Parameter token: The opaque token returned during registration.
  public func cancel(_ token: Any) { _cancel(token) }
}

public extension ServiceLocator {
  /// Returns a process-wide, type-erased bus for event type `E`.
  ///
  /// This is equivalent to `AnyEventBus(resolve(E.self))` and is convenient when you only
  /// need an `AnyEventBus` to wire into a relay.
  static func anyBus<E>(_: E.Type) -> AnyEventBus { AnyEventBus(resolve(E.self)) }
}
