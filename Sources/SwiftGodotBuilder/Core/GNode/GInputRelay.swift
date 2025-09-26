import SwiftGodot
import SwiftGodotPatterns

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
