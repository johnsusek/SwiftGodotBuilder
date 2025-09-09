import SwiftGodot

/// A timeboxed ability/attack specification.
///
/// Use this to describe three typical phases of a game ability:
/// **startup**, **active**, and **recovery**. All durations are in
/// seconds and are meant to be advanced by passing per-frame delta time
/// (e.g. from Godot's `_process`/`_physicsProcess`) to ``AbilityRunner/tick(_:)``.
///
/// The `hitboxOffset` can be applied by your gameplay code when the ability
/// becomes ``AbilityRunner/Phase-swift.enum/active`` (see
/// ``AbilityRunner/onActive``).
public struct AbilitySpec {
  /// Stable identifier for the ability (e.g. `"kick"`).
  public let name: String

  /// Time in seconds before the ability becomes **active**.
  ///
  /// During startup the move can be displayed/queued, but it does not yet
  /// produce a hitbox.
  public let startup: Double

  /// Time in seconds the ability's hitbox is considered **active**.
  ///
  /// This is the window in which collisions/contacts should be tested.
  public let active: Double

  /// Time in seconds required to **recover** after the active window ends.
  ///
  /// During recovery, inputs may be buffered by your higher-level input system,
  /// but the current ability is still in progress.
  public let recovery: Double

  /// Positional offset to apply to the hitbox when the ability becomes active.
  ///
  /// The coordinate system follows Godot's 2D conventions (`+x` right, `+y` down).
  /// If your character faces left/right, you may want to flip this along the X-axis.
  public let hitboxOffset: Vector2

  /// Creates a new ability specification.
  public init(_ name: String, startup: Double, active: Double, recovery: Double, hitboxOffset: Vector2) {
    self.name = name
    self.startup = startup
    self.active = active
    self.recovery = recovery
    self.hitboxOffset = hitboxOffset
  }
}

/// A state machine that advances an ability through
/// startup -> active -> recovery using per-frame delta time.
///
/// ``AbilityRunner`` does not schedule or read inputs; it only tracks time and
/// transitions, exposing three lifecycle callbacks (``onBegan``, ``onActive``,
/// ``onEnded``). Drive it once per frame by calling ``tick(_:)``.
///
/// ### Reentrancy
/// Calling ``begin(_:)`` while ``busy`` will **interrupt** the current ability
/// and start the new one immediately. If you prefer to ignore inputs while
/// busy, check ``busy`` before calling ``begin(_:)``.
///
/// ### Example
/// ```swift
/// final class Player: CharacterBody2D {
///   private let runner = AbilityRunner()
///   private let kick = AbilitySpec("kick", startup: 0.08, active: 0.12, recovery: 0.20, hitboxOffset: Vector2(14, 6))
///
///   override func _ready() {
///     runner.onBegan = { spec in /* play windup anim for spec.name */ }
///     runner.onActive = { spec in /* spawn/enable hitbox at spec.hitboxOffset */ }
///     runner.onEnded = { _ in /* return to idle, clear hitbox */ }
///   }
///
///   override func _physicsProcess(delta: Double) {
///     // Input layer decides *when* to start an ability
///     if Input.isActionJustPressed(action: "kick"), !runner.busy { runner.begin(kick) }
///
///     // Advance ability timing each frame
///     runner.tick(delta)
///   }
/// }
/// ```
public final class AbilityRunner {
  /// Discrete phases of an ability's lifecycle.
  public enum Phase { case idle, startup, active, recovery }

  /// Current phase of the runner. Read-only from the outside.
  public private(set) var phase: Phase = .idle

  /// Internal accumulator for phase time (seconds).
  private var t = 0.0

  /// Currently running spec, if any.
  private var spec: AbilitySpec?

  /// Invoked immediately when ``begin(_:)`` starts a spec (phase becomes `startup`).
  ///
  /// Use this to trigger wind-up animation, SFX, or VFX.
  public var onBegan: ((AbilitySpec) -> Void)?

  /// Invoked exactly once at the transition into the `active` phase.
  ///
  /// Spawn/enable your hitbox here using ``AbilitySpec/hitboxOffset``.
  public var onActive: ((AbilitySpec) -> Void)?

  /// Invoked exactly once when recovery completes and the runner returns to `idle`.
  ///
  /// Use this to clean up effects and return to neutral animation.
  public var onEnded: ((AbilitySpec) -> Void)?

  /// Convenience: `true` if the runner is presently in the `active` phase.
  public var isActive: Bool { phase == .active }

  /// `true` if an ability is in progress (any phase other than `idle`).
  public var busy: Bool { phase != .idle }

  /// Creates a new, empty ability runner.
  public init() {}

  /// Starts (or restarts) an ability with the given specification.
  ///
  /// - Important: This **interrupts** any currently running ability. If you
  ///   want to prevent interruptions, check ``busy`` before calling.
  public func begin(_ s: AbilitySpec) {
    spec = s
    phase = .startup
    t = 0
    onBegan?(s)
  }

  /// Advances the internal timer and performs phase transitions.
  ///
  /// Call this once per frame with `dt` in seconds. This method fires
  /// ``onActive`` when entering the active phase and ``onEnded`` when recovery
  /// completes.
  public func tick(_ dt: Double) {
    guard let s = spec, phase != .idle else { return }

    t += dt

    switch phase {
    case .startup:
      if t >= s.startup {
        phase = .active
        t = 0
        onActive?(s)
      }
    case .active:
      if t >= s.active {
        phase = .recovery
        t = 0
      }
    case .recovery:
      if t >= s.recovery {
        phase = .idle
        onEnded?(s)
        spec = nil
      }
    case .idle:
      break
    }
  }
}
