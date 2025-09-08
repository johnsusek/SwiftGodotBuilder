import Foundation

/// A frame-friendly cooldown timer.
///
/// Use this to enforce a minimum interval between actions (e.g., firing a
/// weapon or triggering a dash). Call ``tryUse()`` at the moment you want to
/// perform the action; it returns `true` only if the cooldown has expired and
/// simultaneously arms the cooldown for the configured ``duration``. Call
/// ``tick(delta:)`` once per update/frame to advance time.
///
/// The internal clock is additive: each `tick(delta:)` subtracts `delta` from
/// the remaining time. When the remaining time reaches zero or below, the
/// cooldown is considered **ready** again.
///
/// - Note: This type performs no scheduling of its own; you must drive it
///   explicitly by calling ``tick(delta:)``.
/// - Important: Changing ``duration`` does **not** modify an in-flight cooldown.
///   If you need the new value to take effect immediately, call ``reset()``
///   and then ``tryUse()`` as needed.
/// - SeeAlso: ``ready``, ``timeLeft``, ``tick(delta:)``, ``tryUse()``, ``reset()``
///
/// ### Usage
/// ```swift
/// var fireCooldown = Cooldown(duration: 0.25)
///
/// // Per input/frame:
/// if wantsToFire, fireCooldown.tryUse() {
///   fireBullet()
/// }
///
/// // In your game loop/update:
/// fireCooldown.tick(delta: frameDeltaSeconds)
/// ```
public final class Cooldown {
  /// The cooldown duration, in seconds.
  ///
  /// You may adjust this at runtime. The new value is used the next time
  /// ``tryUse()`` succeeds; it does not retroactively alter an already
  /// running cooldown.
  public var duration: Double

  /// Internal remaining time in seconds. Values at or below zero indicate the
  /// cooldown is ready. Kept private; use ``timeLeft`` for a clamped view.
  private var remaining = 0.0

  /// Creates a cooldown with the given duration (seconds).
  /// - Parameter duration: Number of seconds to wait after each successful use.
  public init(duration: Double) { self.duration = duration }

  /// Whether the cooldown is currently ready (no waiting time remaining).
  public var ready: Bool { remaining <= 0 }

  /// The non-negative remaining time (seconds) until the cooldown is ready.
  ///
  /// This value is clamped to `>= 0` for convenience.
  public var timeLeft: Double { max(0, remaining) }

  /// Attempts to use the cooldown.
  ///
  /// If the cooldown is ready, this arms it by setting the remaining time to
  /// ``duration`` and returns `true`. If it is still cooling down, this does
  /// nothing and returns `false`.
  ///
  /// - Returns: `true` if the use succeeded and the cooldown was (re)started.
  @discardableResult
  public func tryUse() -> Bool {
    if !ready { return false }
    remaining = duration
    return true
  }

  /// Advances the cooldown's internal clock.
  ///
  /// Call this once per update/frame to decrement the remaining time.
  /// Passing a non-positive `delta` is a no-op.
  ///
  /// - Parameter delta: Elapsed time in seconds since the last tick.
  public func tick(delta: Double) {
    if remaining <= 0 { return }
    remaining -= delta
  }

  /// Immediately clears the cooldown, making it ready.
  ///
  /// After calling this, ``ready`` will be `true` and ``timeLeft`` will be `0`.
  public func reset() { remaining = 0 }
}
