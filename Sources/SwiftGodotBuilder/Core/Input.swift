import SwiftGodot
import SwiftGodotPatterns

// MARK: - API Surface

public struct InputPhase: OptionSet {
  public let rawValue: Int
  public init(rawValue: Int) { self.rawValue = rawValue }
  public static let pressed = InputPhase(rawValue: 1 << 0)
  public static let released = InputPhase(rawValue: 1 << 1)
  public static let echo = InputPhase(rawValue: 1 << 2)
}

public enum InputScope { case raw, unhandled, shortcut, unhandledKey }

public enum InputMatch {
  case any
  case pressed, released, echo
  case key(Key)
  case mouse(MouseButton)
  case joyButton(JoyButton)
  case action(String) // InputMap action
}

public extension GNode where T: Node {
  // Generic event hook with filter list
  func onInput(_ match: [InputMatch],
               scope: InputScope = .unhandled,
               _ handler: @escaping (T, InputEvent) -> Void) -> Self
  {
    var s = self
    s.ops.append { host in
      let relay = GInputRelay()
      relay.scope = scope
      relay.anyHandlers.append(.init(owner: host, filter: .compile(match)) { node, ev in
        guard let typed = node as? T else { return }
        handler(typed, ev)
      })
      host.addChild(node: relay)
    }
    return s
  }

  // Typed key events
  func onKey(_ key: Key? = nil,
             when: InputPhase = [.pressed],
             scope: InputScope = .unhandled,
             _ handler: @escaping (T, InputEventKey) -> Void) -> Self
  {
    var s = self
    s.ops.append { host in
      let relay = GInputRelay()
      relay.scope = scope
      relay.keyHandlers.append(.init(owner: host, key: key, phases: when) { node, ev in
        guard let typed = node as? T, let kev = ev as? InputEventKey else { return }
        handler(typed, kev)
      })
      host.addChild(node: relay)
    }
    return s
  }

  // Typed mouse button events
  func onMouse(_ button: MouseButton? = nil,
               when: InputPhase = [.pressed],
               scope: InputScope = .unhandled,
               _ handler: @escaping (T, InputEventMouseButton) -> Void) -> Self
  {
    var s = self
    s.ops.append { host in
      let relay = GInputRelay()
      relay.scope = scope
      relay.mouseHandlers.append(.init(owner: host, button: button, phases: when) { node, ev in
        guard let typed = node as? T, let mev = ev as? InputEventMouseButton else { return }
        handler(typed, mev)
      })
      host.addChild(node: relay)
    }
    return s
  }

  // InputMap action match on events (no polling)
  func onAction(_ name: String,
                when: InputPhase = [.pressed],
                scope: InputScope = .unhandled,
                _ handler: @escaping (T) -> Void) -> Self
  {
    var s = self
    s.ops.append { host in
      let relay = GInputRelay()
      relay.scope = scope
      relay.actionHandlers.append(.init(owner: host, action: StringName(name), phases: when) { node in
        guard let typed = node as? T else { return }
        handler(typed)
      })
      host.addChild(node: relay)
    }
    return s
  }
}

// MARK: - Relay Node

@Godot
public final class GInputRelay: Node {
  struct AnyHandler {
    weak var owner: Node?
    let filter: _CompiledFilter
    let call: (Node, InputEvent) -> Void
  }

  struct KeyHandler {
    weak var owner: Node?
    let key: Key?
    let phases: InputPhase
    let call: (Node, InputEvent) -> Void
  }

  struct MouseHandler {
    weak var owner: Node?
    let button: MouseButton?
    let phases: InputPhase
    let call: (Node, InputEvent) -> Void
  }

  struct ActionHandler {
    weak var owner: Node?
    let action: StringName
    let phases: InputPhase
    let call: (Node) -> Void
  }

  var scope: InputScope = .unhandled
  var anyHandlers: [AnyHandler] = []
  var keyHandlers: [KeyHandler] = []
  var mouseHandlers: [MouseHandler] = []
  var actionHandlers: [ActionHandler] = []

  override public func _ready() {
    switch scope {
    case .raw: setProcessInput(enable: true)
    case .unhandled: setProcessUnhandledInput(enable: true)
    case .shortcut: setProcessShortcutInput(enable: true)
    case .unhandledKey: setProcessUnhandledKeyInput(enable: true)
    }
  }

  override public func _input(event: InputEvent?) {
    guard let event else { return }
    if scope == .raw { route(event) }
  }

  override public func _unhandledInput(event: InputEvent?) {
    guard let event else { return }
    if scope == .unhandled { route(event) }
  }

  override public func _shortcutInput(event: InputEvent?) {
    guard let event else { return }
    if scope == .shortcut { route(event) }
  }

  override public func _unhandledKeyInput(event: InputEvent?) {
    guard let event else { return }
    if scope == .unhandledKey { route(event) }
  }

  func route(_ event: InputEvent) {
    if !actionHandlers.isEmpty { routeActions(event) }
    if let kev = event as? InputEventKey, !keyHandlers.isEmpty { routeKeys(kev) }
    if let mev = event as? InputEventMouseButton, !mouseHandlers.isEmpty { routeMouse(mev) }
    for h in anyHandlers {
      guard let owner = h.owner, h.filter.matches(event) else { continue }
      h.call(owner, event)
    }
  }

  func routeActions(_ ev: InputEvent) {
    for h in actionHandlers {
      guard let owner = h.owner else { continue }
      if h.phases.contains(.pressed), ev.isActionPressed(action: h.action) { h.call(owner)
        continue
      }
      if h.phases.contains(.released), ev.isActionReleased(action: h.action) { h.call(owner)
        continue
      }
    }
  }

  func routeKeys(_ kev: InputEventKey) {
    for h in keyHandlers {
      guard let owner = h.owner else { continue }
      if let want = h.key, kev.physicalKeycode != want { continue }
      if kev.pressed {
        if kev.echo { if h.phases.contains(.echo) { h.call(owner, kev) } }
        else if h.phases.contains(.pressed) { h.call(owner, kev) }
      } else if h.phases.contains(.released) {
        h.call(owner, kev)
      }
    }
  }

  func routeMouse(_ mev: InputEventMouseButton) {
    for h in mouseHandlers {
      guard let owner = h.owner else { continue }
      if let want = h.button, mev.buttonIndex != want { continue }
      if mev.pressed { if h.phases.contains(.pressed) { h.call(owner, mev) } }
      else if h.phases.contains(.released) { h.call(owner, mev) }
    }
  }
}

// MARK: - Filter compiler for the generic variant

struct _CompiledFilter {
  enum Kind { case any, key(Key), mouse(MouseButton), joy(JoyButton), action(StringName) }
  let kind: Kind
  let phases: InputPhase
  let acceptEcho: Bool

  static func compile(_ parts: [InputMatch]) -> _CompiledFilter {
    var kind: Kind = .any
    var phases: InputPhase = []
    var acceptEcho = false
    for p in parts {
      switch p {
      case .any: kind = .any
      case .pressed: phases.insert(.pressed)
      case .released: phases.insert(.released)
      case .echo: acceptEcho = true
      case let .key(k): kind = .key(k)
      case let .mouse(b): kind = .mouse(b)
      case let .joyButton(b): kind = .joy(b)
      case let .action(name): kind = .action(StringName(name))
      }
    }
    if phases.isEmpty { phases = [.pressed] }
    return .init(kind: kind, phases: phases, acceptEcho: acceptEcho)
  }

  func matches(_ ev: InputEvent) -> Bool {
    switch kind {
    case .any:
      return matchesPhase(ev)
    case let .key(k):
      guard let kev = ev as? InputEventKey, kev.physicalKeycode == k else { return false }
      return matchesKeyPhase(kev)
    case let .mouse(b):
      guard let mev = ev as? InputEventMouseButton, mev.buttonIndex == b else { return false }
      return matchesMousePhase(mev)
    case let .joy(b):
      guard let jev = ev as? InputEventJoypadButton, jev.buttonIndex == b else { return false }
      return matchesButtonPhase(jev.pressed)
    case let .action(name):
      if phases.contains(.pressed), ev.isActionPressed(action: name) { return true }
      if phases.contains(.released), ev.isActionReleased(action: name) { return true }
      return false
    }
  }

  private func matchesPhase(_ ev: InputEvent) -> Bool {
    if let kev = ev as? InputEventKey { return matchesKeyPhase(kev) }
    if let mev = ev as? InputEventMouseButton { return matchesMousePhase(mev) }
    if let btn = ev as? InputEventJoypadButton { return matchesButtonPhase(btn.pressed) }
    return false
  }

  private func matchesKeyPhase(_ kev: InputEventKey) -> Bool {
    if kev.echo { return acceptEcho }
    return kev.pressed ? phases.contains(.pressed) : phases.contains(.released)
  }

  private func matchesMousePhase(_ mev: InputEventMouseButton) -> Bool {
    return mev.pressed ? phases.contains(.pressed) : phases.contains(.released)
  }

  private func matchesButtonPhase(_ pressed: Bool) -> Bool {
    return pressed ? phases.contains(.pressed) : phases.contains(.released)
  }
}
