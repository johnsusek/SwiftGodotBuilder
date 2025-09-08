import SwiftGodot

/// Per-frame button state with edge detection.
///
/// `PressState` tracks three booleans commonly needed for input handling:
/// - ``down``: whether the control is currently held
/// - ``pressed``: became held **this frame** (rising edge)
/// - ``released``: became unheld **this frame** (falling edge)
///
/// Call ``update(isDown:)`` once per frame with the current physical/virtual
/// state to advance edges. Edges are computed by comparing the new state to the
/// previously observed state.
public struct PressState {
  /// `true` while the control is held on this frame.
  public var down = false

  /// `true` only on the frame where `down` transitions `false → true`.
  public var pressed = false

  /// `true` only on the frame where `down` transitions `true → false`.
  public var released = false

  /// Advances this state machine using the current raw state.
  ///
  /// - Parameter isDown: The instantaneous state for this frame.
  ///
  /// On each call:
  /// - ``pressed`` becomes `true` iff `isDown` is `true` and ``down`` was `false`.
  /// - ``released`` becomes `true` iff `isDown` is `false` and ``down`` was `true`.
  /// - ``down`` is then updated to `isDown`.
  public mutating func update(isDown: Bool) {
    pressed = isDown && !down
    released = !isDown && down
    down = isDown
  }
}

/// Snapshot of multiple Godot input actions with edge-detected states.
///
/// `InputSnapshot` polls a set of Godot action names each frame using
/// `Input.isActionPressed`, storing a ``PressState`` per action (keyed by
/// `StringName`). Read convenience accessors like ``down(_:)``/``pressed(_:)``/``released(_:)``
/// after calling ``poll(_:)``.
///
/// ### Usage
/// ```swift
/// final class Player: CharacterBody2D {
///   private var input = InputSnapshot()
///   private let actions = ["move_left", "move_right", "jump", "attack"]
///
///   override func _physicsProcess(delta: Double) {
///     input.poll(actions)
///
///     if input.pressed("jump") { /* start jump */ }
///     if input.down("move_left") { /* apply left movement */ }
///     if input.released("attack") { /* finish attack charge */ }
///   }
/// }
/// ```
///
/// - Note: Only actions passed to ``poll(_:)`` are updated on a given frame.
///   Omitting an action leaves its previously stored state unchanged.
public struct InputSnapshot {
  /// Backing store of action states keyed by action `StringName`.
  public var map: [StringName: PressState] = [:]

  /// Creates an empty snapshot.
  public init() {}

  /// Polls the given action names and updates their states for this frame.
  ///
  /// - Parameter actions: Godot input action names (as configured in the project).
  ///
  /// For each `name`, this calls `Input.isActionPressed(action:)` and updates the
  /// per-action ``PressState``. Actions not listed are left untouched this frame.
  public mutating func poll(_ actions: [String]) {
    for name in actions {
      let key = StringName(name)
      var state = map[key] ?? PressState()
      state.update(isDown: Input.isActionPressed(action: key))
      map[key] = state
    }
  }

  /// Returns `true` if the named action is currently held.
  @inlinable public func down(_ name: String) -> Bool { map[StringName(name)]?.down == true }

  /// Returns `true` only on the frame when the named action transitions to held.
  @inlinable public func pressed(_ name: String) -> Bool { map[StringName(name)]?.pressed == true }

  /// Returns `true` only on the frame when the named action transitions to unheld.
  @inlinable public func released(_ name: String) -> Bool { map[StringName(name)]?.released == true }
}
