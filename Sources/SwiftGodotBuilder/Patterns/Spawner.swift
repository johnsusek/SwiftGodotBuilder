/// A timer-driven generator of objects at a target rate.
///
/// `Spawner` counts down in `tick(delta:)` and, when its internal clock
/// reaches zero, it creates or acquires one object, fires hooks in a
/// well-defined order, and schedules the next spawn using `rate` and `jitter`.
///
/// You can supply objects from:
/// - a pool via `usePool(_:)`, or
/// - a factory closure via `make`.
/// If both are set, the pool is tried first and the factory is a fallback.
///
/// ### Scheduling
/// - `rate` is in **spawns per second** (e.g. `2.0` -> every 0.5s).
/// - `jitter` adds a uniform random offset in seconds in the range
///   `[-jitter, +jitter]` to the base interval. The final interval is clamped
///   to be non-negative.
/// - `reset(scheduleImmediately:)` sets when the next spawn will occur:
///   - `true` -> on the very next `tick` call,
///   - `false` -> after one full (possibly jittered) interval.
/// - Large `delta` values produce **at most one** spawn per `tick` call; missed
///   intervals do not “catch up” with multiple spawns.
///
/// ### Example
/// ```swift
/// let spawner = Spawner<Bullet>()
/// spawner.rate = 5           // 5 bullets/sec
/// spawner.jitter = 0.05      // small timing variance
/// spawner.make = { Bullet() } // or spawner.usePool(pool.acquire)
///
/// spawner.onSpawn = { b in
///   b.configureAndAttach()
/// }
///
/// spawner.reset() // spawn on next tick
///
/// // Game loop:
/// func _process(delta: Double) {
///   spawner.tick(delta: delta)
/// }
/// ```
public final class Spawner<T> {
  /// Target frequency in spawns per second.
  ///
  /// Values `<= 0` are treated as a very small positive rate internally to avoid
  /// division by zero when computing the next interval.
  public var rate: Double = 1.0 // spawns/sec

  /// Uniform random timing variance in seconds, applied as `±jitter`.
  ///
  /// The final interval is clamped to be non-negative.
  public var jitter: Double = 0.0 // +/- seconds

  /// Master enable/disable flag. When `false`, `tick(delta:)` does nothing.
  public var enabled = true

  /// Optional factory used when not drawing from a pool (or when the pool is empty).
  ///
  /// When both a pool and a factory are set, the pool is attempted first.
  public var make: (() -> T?)? // factory if not using a pool

  /// Called after a successful spawn to let the host attach, position, etc.
  public var onSpawn: ((T) -> Void)? // host attaches/positions/etc.

  /// Optional hook called immediately **before** attempting to create/acquire an object.
  ///
  /// Runs even if the spawn later fails (e.g., pool is empty and `make` is `nil`).
  public var preSpawn: (() -> Void)? // optional hook

  /// Optional hook called **after** `onSpawn` for successful spawns.
  public var postSpawn: ((T) -> Void)? // optional hook

  /// Closure used to pull an instance from a pool, if configured via `usePool(_:)`.
  private var poolAcquire: (() -> T?)?

  /// Countdown timer to the next spawn (seconds).
  private var nextAt = 0.0

  public init() {}

  /// Configure the spawner to acquire objects from a pool.
  ///
  /// If both a pool and `make` are set, the pool is preferred and `make` is a fallback.
  /// - Parameter acquire: Closure that returns a pooled object or `nil`.
  public func usePool(_ acquire: @escaping () -> T?) { poolAcquire = acquire }

  /// Resets and reschedules the next spawn.
  ///
  /// - Parameter scheduleImmediately: When `true` (default), the next call to
  ///   `tick` will attempt to spawn immediately. When `false`, the next spawn
  ///   occurs after one full (possibly jittered) interval.
  public func reset(scheduleImmediately: Bool = true) {
    nextAt = scheduleImmediately ? 0 : nextInterval()
  }

  /// Advances the internal timer and performs a spawn when due.
  ///
  /// Call this once per frame or tick with the elapsed time since the last call.
  /// At most one spawn occurs per `tick` call.
  ///
  /// - Parameter delta: Elapsed time in seconds.
  public func tick(delta: Double) {
    if !enabled { return }
    nextAt -= delta
    if nextAt > 0 { return }
    spawnOnce()
    nextAt = nextInterval()
  }

  /// Computes the next interval (seconds) from `rate` and `jitter`.
  ///
  /// Base interval is `1 / max(0.0001, rate)`. If `jitter > 0`, a random
  /// offset in `[-jitter, +jitter]` is added, then clamped to `>= 0`.
  private func nextInterval() -> Double {
    let base = 1.0 / max(0.0001, rate)
    if jitter <= 0 { return base }
    return max(0.0, base + Double.random(in: -jitter ... jitter))
  }

  /// Performs a single spawn attempt and fires hooks in the documented order.
  private func spawnOnce() {
    preSpawn?()
    guard let obj = poolAcquire?() ?? make?() else { return }
    onSpawn?(obj)
    postSpawn?(obj)
  }
}
