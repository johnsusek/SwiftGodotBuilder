import SwiftGodot
import SwiftGodotPatterns

/// A Godot node that bridges an `EventHub` into the scene,
/// and relays payloads to registered receivers.
@Godot
public final class GEventRelay: Node {
  /// The type-erased event hub to subscribe to.
  ///
  /// Set this before the node enters the tree; if `nil` at `_ready`, no subscription
  /// is created. You can build an instance via ``AnyEventHub`` or
  /// ``GlobalEventBuses/anyHub(_:)``.
  public var hub: AnyEventHub?

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

  /// Opaque tokens returned by the hub, used to cancel on exit.
  private var tokEach: Any?
  private var tokBatch: Any?

  /// Godot lifecycle hook: subscribes to the hub, if present.
  ///
  /// Subscriptions are captured weakly to avoid retaining the relay.
  override public func _ready() {
    guard let hub else { return }
    tokEach = hub.onEach { [weak self] any in self?.routeEach(any) }
    tokBatch = hub.onBatch { [weak self] arr in self?.routeBatch(arr) }
  }

  /// Godot lifecycle hook: cancels subscriptions and clears receiver lists.
  override public func _exitTree() {
    if let hub, let t = tokEach { hub.cancel(t) }
    if let hub, let t = tokBatch { hub.cancel(t) }
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

/// A lightweight wrapper around a weak object reference.
///
/// Useful for keeping ties to Godot `Node`s (or any class) without preventing deallocation.
public struct Weak<T: AnyObject> {
  /// The underlying weak reference.
  public weak var value: T?

  /// Creates a new weak wrapper.
  /// - Parameter v: The object to wrap.
  public init(_ v: T?) { value = v }
}

/// Type-erased facade over `EventHub<E>`.
///
/// `AnyEventHub` hides the concrete `Event` type, exposing:
/// - ``onEach(_:)`` delivering `Any` payloads,
/// - ``onBatch(_:)`` delivering `[Any]`,
/// - ``cancel(_:)`` accepting the opaque token returned by registration.
///
/// Tokens are stored as `Any` but are still the underlying `EventHub<E>.Token`.
public struct AnyEventHub {
  private let _onEach: (@escaping (Any) -> Void) -> Any
  private let _onBatch: (@escaping ([Any]) -> Void) -> Any
  private let _cancel: (Any) -> Void

  /// Wraps a concrete `EventHub<E>` into a type-erased hub.
  /// - Parameter hub: The strongly typed hub to wrap.
  public init<E>(_ hub: EventHub<E>) {
    _onEach = { h in hub.onEach { h($0) } }
    _onBatch = { h in hub.onBatch { h($0) } }
    _cancel = { tok in if let t = tok as? EventHub<E>.Token { hub.cancel(t) } }
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

public extension GlobalEventBuses {
  /// Returns a process-wide, type-erased hub for event type `E`.
  ///
  /// This is equivalent to `AnyEventHub(hub(E.self))` and is convenient when you only
  /// need an `AnyEventHub` to wire into a relay.
  static func anyHub<E>(_: E.Type) -> AnyEventHub { AnyEventHub(hub(E.self)) }
}
