//
//  Actions.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

// MARK: - Event modeling

/// Describes a single input event in a declarative, strongly-typed way.
/// Use these to build actions without hard-coding raw integers.
public enum InputEventSpec {
  /// Keyboard event using a Godot `Key` (physical scancode).
  case key(_ key: Key)
  /// Joypad button event for a specific device and button.
  case joyButton(device: Int, button: JoyButton)
  /// Joypad axis motion event with a signed axis value (−1.0…1.0).
  case joyAxis(device: Int, axis: JoyAxis, value: Double)
  /// Mouse button event by numerical index (mapped to `MouseButton`).
  case mouseButton(index: Int)

  /// Builds the corresponding Godot `InputEvent` instance.
  ///
  /// This materializes the declarative spec into an engine object that
  /// can be registered with `InputMap`. Defaults `pressed` to `false`
  /// for button/keyboard types to represent the "binding" rather than state.
  func make() -> InputEvent {
    switch self {
    case let .key(key):
      let e = InputEventKey()
      e.physicalKeycode = key
      return e
    case let .joyButton(device, button):
      let e = InputEventJoypadButton()
      e.device = Int32(device)
      e.buttonIndex = button
      return e
    case let .joyAxis(device, axis, value):
      let e = InputEventJoypadMotion()
      e.device = Int32(device)
      e.axis = axis
      e.axisValue = value
      return e
    case let .mouseButton(index):
      let e = InputEventMouseButton()
      e.buttonIndex = MouseButton(rawValue: Int64(index)) ?? .none
      return e
    }
  }
}

// MARK: - Action modeling

/// A named input action and the set of events that trigger it.
///
/// Use `installing(clearExisting:)` to register this action with `InputMap`.
public struct ActionSpec {
  /// Action name as used by Godot’s `InputMap` and `Input.is_action_*` APIs.
  public let name: String
  /// Optional deadzone to apply to the action (commonly for analog axes).
  public let deadzone: Double?
  /// Events (keys, buttons, axes, mouse) that will trigger this action.
  public let events: [InputEventSpec]

  /// Creates a new `ActionSpec`.
  public init(_ name: String, deadzone: Double? = nil, events: [InputEventSpec]) {
    self.name = name; self.deadzone = deadzone; self.events = events
  }

  /// Registers this action and its events with Godot’s `InputMap`.
  ///
  /// - Parameter clearExisting: If `true`, erases any existing events
  ///   for this action before adding the new ones.
  public func installing(clearExisting: Bool = false) {
    let sn = StringName(name)
    if !InputMap.hasAction(sn) { InputMap.addAction(sn) }
    if let dz = deadzone { InputMap.actionSetDeadzone(action: sn, deadzone: Double(dz)) }
    if clearExisting { InputMap.actionEraseEvents(action: sn) }
    for e in events {
      InputMap.actionAddEvent(action: sn, event: e.make())
    }
  }
}

// MARK: - Builders

/// Result builder for composing `[InputEventSpec]` in a DSL block.
///
/// Enables:
/// ```swift
/// Action("jump") {
///   Key(.space)
///   JoyButton(0, .a)
/// }
/// ```
@resultBuilder
public enum InputEventBuilder {
  public static func buildBlock(_ parts: [InputEventSpec]...) -> [InputEventSpec] { parts.flatMap { $0 } }
  public static func buildExpression(_ e: InputEventSpec) -> [InputEventSpec] { [e] }
  public static func buildExpression(_ es: [InputEventSpec]) -> [InputEventSpec] { es }
  public static func buildOptional(_ e: [InputEventSpec]?) -> [InputEventSpec] { e ?? [] }
  public static func buildEither(first: [InputEventSpec]) -> [InputEventSpec] { first }
  public static func buildEither(second: [InputEventSpec]) -> [InputEventSpec] { second }
  public static func buildArray(_ arr: [[InputEventSpec]]) -> [InputEventSpec] { arr.flatMap { $0 } }
}

/// Result builder for composing `[ActionSpec]` in a DSL block.
///
/// Enables:
/// ```swift
/// Actions {
///   Action("fire") { MouseButton(1) }
///   Action("left") { Key(.a) }
///   Action("right") { Key(.d) }
/// }
/// ```
@resultBuilder
public enum ActionBuilder {
  public static func buildBlock(_ parts: [ActionSpec]...) -> [ActionSpec] { parts.flatMap { $0 } }
  public static func buildExpression(_ a: ActionSpec) -> [ActionSpec] { [a] }
  public static func buildExpression(_ asv: [ActionSpec]) -> [ActionSpec] { asv }
  public static func buildOptional(_ a: [ActionSpec]?) -> [ActionSpec] { a ?? [] }
  public static func buildEither(first: [ActionSpec]) -> [ActionSpec] { first }
  public static func buildEither(second: [ActionSpec]) -> [ActionSpec] { second }
  public static func buildArray(_ arr: [[ActionSpec]]) -> [ActionSpec] { arr.flatMap { $0 } }
}

// MARK: - DSL surface

/// Top-level container for a set of actions to be installed into `InputMap`.
///
/// Example:
/// ```swift
/// let inputs = Actions {
///   Action("jump") { Key(.space) }
///   Action("shoot") { MouseButton(1) }
/// }
/// inputs.install(clearExisting: true)
/// ```
public struct Actions {
  /// The actions to be installed.
  public let actions: [ActionSpec]

  /// Builds an `Actions` from a declarative block of `ActionSpec`s.
  public init(@ActionBuilder _ content: () -> [ActionSpec]) { actions = content() }

  /// Installs all actions into the `InputMap` in declaration order.
  ///
  /// - Parameter clearExisting: When `true`, purges existing events for each
  ///   action name before re-adding the declared bindings.
  public func install(clearExisting: Bool = false) {
    for a in actions {
      a.installing(clearExisting: clearExisting)
    }
  }
}

/// Convenience function for building a single `ActionSpec` with an `InputEventBuilder` block.
///
/// Example:
/// ```swift
/// Action("move_left", deadzone: 0.2) {
///   JoyAxis(0, .leftX, -1)
///   Key(.a)
/// }
/// ```
@inlinable public func Action(
  _ name: String,
  deadzone: Double? = nil,
  @InputEventBuilder events: () -> [InputEventSpec]
) -> ActionSpec {
  ActionSpec(name, deadzone: deadzone, events: events())
}

// MARK: - Sugar for event literals inside InputEventBuilder

/// Shorthand constructor for a keyboard event.
@inlinable public func Key(_ key: Key) -> InputEventSpec { .key(key) }

/// Shorthand constructor for a joypad button event.
@inlinable public func JoyButton(_ button: JoyButton, device: Int) -> InputEventSpec {
  .joyButton(device: device, button: button)
}

/// Shorthand constructor for a joypad axis event.
@inlinable public func JoyAxis(_ axis: JoyAxis, device: Int, _ value: Double) -> InputEventSpec {
  .joyAxis(device: device, axis: axis, value: value)
}

/// Shorthand constructor for a mouse button event (by integer index).
@inlinable public func MouseButton(_ index: Int) -> InputEventSpec { .mouseButton(index: index) }

// MARK: - Recipes

/// Ready-made helpers that expand into multiple `ActionSpec`s for common patterns.
/// Useful for mapping analog axes to paired digital actions (e.g. up/down, left/right).
public enum ActionRecipes {
  /// Produces `<prefix>_down` and `<prefix>_up` actions for a vertical axis.
  ///
  /// Each action includes the axis motion plus any optional key or button,
  /// with a shared deadzone applied to both.
  ///
  /// - Parameters:
  ///   - namePrefix: Action name prefix, e.g. `"move"` → `"move_down"`, `"move_up"`.
  ///   - device: Joypad device index.
  ///   - axis: The joypad axis to sample.
  ///   - dz: Deadzone for both actions (default `0.2`).
  ///   - keyDown/keyUp: Optional keyboard keys to include.
  ///   - btnDown/btnUp: Optional joypad buttons to include.
  /// - Returns: Two `ActionSpec`s: `*_down` (value `+1.0`) and `*_up` (value `-1.0`).
  @inlinable public static func axisUD(
    namePrefix: String,
    device: Int,
    axis: JoyAxis,
    dz: Double = 0.2,
    keyDown: Key? = nil, keyUp: Key? = nil,
    btnDown: JoyButton? = nil, btnUp: JoyButton? = nil
  ) -> [ActionSpec] {
    let downEv: [InputEventSpec] = [
      .joyAxis(device: device, axis: axis, value: 1.0),
      keyDown.map { .key($0) },
      btnDown.map { .joyButton(device: device, button: $0) },
    ].compactMap { $0 }

    let upEv: [InputEventSpec] = [
      .joyAxis(device: device, axis: axis, value: -1.0),
      keyUp.map { .key($0) },
      btnUp.map { .joyButton(device: device, button: $0) },
    ].compactMap { $0 }

    return [
      ActionSpec("\(namePrefix)_down", deadzone: dz, events: downEv),
      ActionSpec("\(namePrefix)_up", deadzone: dz, events: upEv),
    ]
  }

  /// Produces `<prefix>_left` and `<prefix>_right` actions for a horizontal axis.
  ///
  /// Mirrors `axisUD` but with left/right semantics and axis values `−1.0/ +1.0`.
  @inlinable public static func axisLR(
    namePrefix: String,
    device: Int,
    axis: JoyAxis,
    dz: Double = 0.2,
    keyLeft: Key? = nil,
    keyRight: Key? = nil,
    btnLeft: JoyButton? = nil,
    btnRight: JoyButton? = nil
  ) -> [ActionSpec] {
    let left: [InputEventSpec] = [
      .joyAxis(device: device, axis: axis, value: -1.0),
      keyLeft.map { .key($0) },
      btnLeft.map { .joyButton(device: device, button: $0) },
    ].compactMap { $0 }

    let right: [InputEventSpec] = [
      .joyAxis(device: device, axis: axis, value: 1.0),
      keyRight.map { .key($0) },
      btnRight.map { .joyButton(device: device, button: $0) },
    ].compactMap { $0 }

    return [
      ActionSpec("\(namePrefix)_left", deadzone: dz, events: left),
      ActionSpec("\(namePrefix)_right", deadzone: dz, events: right),
    ]
  }
}
