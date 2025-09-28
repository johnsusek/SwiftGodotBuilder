import SwiftGodot
import SwiftGodotPatterns

private let _gProcessRelayName = StringName("__GProcessRelay__")

private func _attachOrUpdateRelay<T: Node>(
  _ host: T,
  onReady: ((T) -> Void)? = nil,
  onProcess: ((T, Double) -> Void)? = nil,
  onPhysics: ((T, Double) -> Void)? = nil
) {
  let relay: GProcessRelay = {
    if let existing: GProcessRelay = host.getChildren()
      .first(where: { $0.name == _gProcessRelayName }) { return existing }
    let r = GProcessRelay()
    r.name = _gProcessRelayName
    r.ownerNode = .init(host)
    host.addChild(node: r)
    return r
  }()

  if let onReady {
    let prev = relay.onReadyCall
    relay.onReadyCall = { [weak host] n in
      guard let typed = host ?? (n as? T) else { return }
      prev?(n)
      onReady(typed)
    }
  }
  if let onProcess {
    let prev = relay.onProcessCall
    relay.onProcessCall = { [weak host] n, dt in
      guard let typed = host ?? (n as? T) else { return }
      prev?(n, dt)
      onProcess(typed, dt)
    }
    relay.setProcess(enable: true)
  }
  if let onPhysics {
    let prev = relay.onPhysicsCall
    relay.onPhysicsCall = { [weak host] n, dt in
      guard let typed = host ?? (n as? T) else { return }
      prev?(n, dt)
      onPhysics(typed, dt)
    }
    relay.setPhysicsProcess(enable: true)
  }
}

public extension GNode where T: Node {
  /// Registers a closure to be called when the node is ready.
  ///
  /// Example:
  /// ```swift
  /// Node2D$()
  ///   .onReady { node in
  ///     // Do something with `node`
  ///   }
  /// ```
  func onReady(_ body: @escaping (T) -> Void) -> Self {
    var s = self
    s.ops.append { host in _attachOrUpdateRelay(host, onReady: body) }
    return s
  }

  /// Registers a closure to be called every frame during the node's process step.
  ///
  /// Example:
  /// ```swift
  /// Node2D$()
  ///   .onProcess { node, delta in
  ///     // Do something with `node` and `delta`
  ///   }
  /// ```
  func onProcess(_ body: @escaping (T, Double) -> Void) -> Self {
    var s = self
    s.ops.append { host in _attachOrUpdateRelay(host, onProcess: body) }
    return s
  }

  /// Registers a closure to be called every frame during the node's physics process step.
  ///
  /// Example:
  /// ```swift
  /// Node2D$()
  ///   .onPhysicsProcess { node, delta in
  ///     // Do something with `node` and `delta`
  ///   }
  /// ```
  func onPhysicsProcess(_ body: @escaping (T, Double) -> Void) -> Self {
    var s = self
    s.ops.append { host in _attachOrUpdateRelay(host, onPhysics: body) }
    return s
  }
}
