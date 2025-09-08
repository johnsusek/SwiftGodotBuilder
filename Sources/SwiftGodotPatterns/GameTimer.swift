import SwiftGodot

/// A manually-driven timer with optional repetition and a timeout callback.
///
/// Drive the timer by calling ``tick(delta:)`` every frame (or on a fixed
/// timestep). When accumulated time reaches ``duration``, the timer fires
/// ``onTimeout``. If ``repeats`` is `true`, it keeps running; otherwise it
/// stops automatically.
///
/// This type does no scheduling on its own - it's just a tiny state machine
/// you advance with your own clock. For one-shot scheduling that integrates
/// with Godot's `SceneTree`, see ``schedule(after:_:)``.
///
/// - Important: Call ``tick(delta:)`` regularly; otherwise time will not advance.
/// - SeeAlso: ``Cooldown`` for enforcing minimum spacing between actions.
public final class GameTimer {
  // MARK: Configuration & State

  /// The target interval, in seconds, between timeouts.
  ///
  /// Changing this value affects the **next** expiration. It does not retroactively
  /// change already accumulated ``elapsed`` time.
  public var duration: Double

  /// Whether the timer should continue running after it fires.
  ///
  /// When `true`, the timer subtracts one `duration` after each fire and keeps
  /// accumulating. When frame `delta` is very large, expirations are coalesced:
  /// at most one `onTimeout` will be delivered per ``tick(delta:)`` call.
  public var repeats: Bool

  /// Whether the timer is currently counting.
  public private(set) var running = false

  /// Time already accumulated toward the next timeout, in seconds.
  public private(set) var elapsed = 0.0

  /// Callback invoked when the timer reaches its ``duration``.
  ///
  /// For repeating timers, this may be called many times over the lifetime
  /// of the timer, but never more than once per call to ``tick(delta:)``.
  public var onTimeout: (() -> Void)?

  /// Creates a timer.
  /// - Parameters:
  ///   - duration: The interval, in seconds, to wait before firing.
  ///   - repeats: If `true`, the timer restarts after firing; otherwise it stops.
  public init(duration: Double = 1.0, repeats: Bool = false) {
    self.duration = duration
    self.repeats = repeats
  }

  // MARK: Introspection

  /// Remaining time, clamped to `>= 0`.
  public var remaining: Double { max(0, duration - elapsed) }

  // MARK: Control

  /// Starts (or restarts) the timer.
  ///
  /// - Parameter d: Optional override for ``duration`` for this start.
  ///   If provided, the property is updated before the timer begins.
  ///
  /// Resets ``elapsed`` to `0` and sets ``running`` to `true`.
  public func start(_ d: Double? = nil) {
    if let d { duration = d }
    elapsed = 0; running = true
  }

  /// Stops the timer without invoking ``onTimeout``.
  ///
  /// Preserves the current ``elapsed`` time; call ``start(_:)`` to resume
  /// from `0` or ``reset()`` to clear accumulated time.
  public func stop() { running = false }

  /// Clears accumulated time without changing the running state.
  ///
  /// After calling this, ``elapsed`` is `0`. If the timer is running,
  /// it begins counting from the start of the interval again.
  public func reset() { elapsed = 0 }

  /// Advances the timer's internal clock.
  ///
  /// Add this to your update loop. When ``elapsed`` reaches or exceeds
  /// ``duration``, the timer fires ``onTimeout``. If ``repeats`` is `true`,
  /// the timer subtracts one `duration` and continues running; otherwise it stops.
  ///
  /// - Parameter delta: Elapsed time in seconds since the last tick. Pass a
  ///   non-negative value; negative values will reduce ``elapsed``.
  public func tick(delta: Double) {
    if !running { return }
    elapsed += delta
    if elapsed < duration { return }
    onTimeout?()
    if repeats { elapsed -= duration; return }
    running = false
  }

  // MARK: Godot Integration

  /// Schedules a one-shot callback using Godot's `SceneTreeTimer`.
  ///
  /// This is an alternative to the manual ``tick(delta:)`` approach when you
  /// simply need "run this after N seconds" behavior integrated with the engine.
  ///
  /// - Parameters:
  ///   - seconds: Delay before firing. Must be `>= 0`.
  ///   - body: Callback to invoke when the timer times out.
  /// - Returns: `true` if the timer was created and connected; otherwise `false`
  ///   (e.g., if there is no active `SceneTree`).
  ///
  /// - Note: This creates a Godot-managed one-shot timer which emits once and
  ///   then frees itself. For repeating behavior, use an instance of `GameTimer`
  ///   and drive it with ``tick(delta:)``.
  public static func schedule(after seconds: Double, _ body: @escaping () -> Void) -> Bool {
    guard seconds >= 0, let tree = Engine.getSceneTree(),
          let t = tree.createTimer(timeSec: seconds) else { return false }
    _ = t.timeout.connect { body() }; return true
  }
}
