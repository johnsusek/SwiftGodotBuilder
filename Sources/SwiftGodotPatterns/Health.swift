/// A game-agnostic hit-point model.
///
/// `Health` clamps values into `0...max`, supports healing and damage (with an
/// `invulnerable` switch), and emits simple callbacks for UI, sound, or game
/// logic to react to changes.
///
/// ### Example
/// ```swift
/// var hp = Health(max: 100)
/// hp.onChanged = { old, new in print("HP: \(old) -> \(new)") }
/// hp.onDied = { print("You died!") }
///
/// hp.damage(30)   // HP: 100 -> 70
/// hp.heal(10)     // HP: 70 -> 80
/// hp.invulnerable = true
/// hp.damage(999)  // no change
/// hp.invulnerable = false
/// hp.damage(200)  // HP: 80 -> 0, prints "You died!", then onDamaged(200)
/// ```
///
/// ### Notes
/// - `setMax(_:clampCurrent:)` can temporarily allow `current > max` when
///   `clampCurrent == false`; a later mutation will re-clamp to the new range.
public final class Health {
  /// The maximum allowed hit points.
  ///
  /// Change via `setMax(_:clampCurrent:)` to optionally clamp `current` into the new range.
  public private(set) var max: Double

  /// The current hit points.
  ///
  /// Always clamped to `0...max` by the mutation APIs in this type. Read-only from outside.
  public private(set) var current: Double

  /// When `true`, `damage(_:)` becomes a no-op.
  public var invulnerable = false

  /// Called after `current` changes.
  ///
  /// - Parameters:
  ///   - old: The previous `current` value.
  ///   - new: The new, clamped `current` value.
  public var onChanged: ((Double, Double) -> Void)? // (old, new)

  /// Called after successful damage is applied (post-clamp).
  ///
  /// - Parameter amount: The raw damage request that was applied. For lethal damage,
  ///   `onDied` may have already fired due to ordering (`set` -> `onDied` -> `onDamaged`).
  public var onDamaged: ((Double) -> Void)? // amount

  /// Called after successful healing is applied (post-clamp).
  ///
  /// - Parameter amount: The raw heal request that was applied.
  public var onHealed: ((Double) -> Void)?

  /// Called whenever `current` is `0` after a `set(_:)` operation.
  ///
  /// This may fire even if `current` was already `0` and remained `0`.
  public var onDied: (() -> Void)?

  /// Creates a new `Health` meter.
  ///
  /// - Parameters:
  ///   - max: Upper bound for health; negative inputs are clamped via later mutations.
  ///   - start: Initial `current` value; defaults to `max`. The actual starting value is clamped to `0...max`.
  public init(max: Double, start: Double? = nil) {
    self.max = max
    current = min(max, start ?? max)
  }

  /// Updates `max` and optionally clamps `current` into the new range.
  ///
  /// - Parameters:
  ///   - m: New maximum; negative inputs are coerced to `0`.
  ///   - clampCurrent: When `true` (default), re-clamps `current` into `0...max`.
  ///     When `false`, `current` may temporarily exceed `max` until the next mutation.
  public func setMax(_ m: Double, clampCurrent: Bool = true) {
    max = Swift.max(0, m)
    if clampCurrent { set(current) }
  }

  /// Sets `current` directly (with clamping) and emits callbacks.
  ///
  /// Order of events:
  /// 1. Clamp into `0...max`.
  /// 2. If changed, call `onChanged(old, new)`.
  /// 3. If the resulting value is `0`, call `onDied()`.
  ///
  /// - Parameter value: New (unclamped) health value.
  public func set(_ value: Double) {
    let old = current
    current = min(max, Swift.max(0, value))
    if current != old { onChanged?(old, current) }
    if current == 0 { onDied?() }
  }

  /// Heals by `amount` and emits callbacks (`onChanged` then `onHealed`).
  ///
  /// - Parameter amount: A positive value to add; non-positive values are ignored.
  public func heal(_ amount: Double) {
    if amount <= 0 { return }
    set(current + amount)
    onHealed?(amount)
  }

  /// Damages by `amount` and emits callbacks (`onChanged`, possibly `onDied`, then `onDamaged`).
  ///
  /// - Parameter amount: A positive value to subtract; ignored when `invulnerable` or non-positive.
  public func damage(_ amount: Double) {
    if invulnerable || amount <= 0 { return }
    set(current - amount)
    onDamaged?(amount)
  }

  /// Convenience boolean indicating whether `current > 0`.
  public var alive: Bool { current > 0 }
}
