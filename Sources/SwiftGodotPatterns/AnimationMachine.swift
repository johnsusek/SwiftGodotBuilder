import SwiftGodot

/// A declarative mapping between gameplay states and animation clips, with
/// optional reverse rules that transition the state machine when an animation finishes.
///
/// Use ``AnimationMachineRules`` to keep rendering policy out of gameplay logic.
///
/// Pair with ``AnimationMachine`` to wire a `StateMachine` to an `AnimatedSprite2D`.
///
/// ### Example
/// ```swift
/// let rules = AnimationMachineRules {
///   When("Idle",   play: "idle")
///   When("Attack", play: "kick", loop: false)
///   When("Hurt",   play: "hurt", loop: false)
///   OnFinish("hurt", go: "Idle")   // when 'hurt' clip finishes, return to Idle
/// }
/// ```
public struct AnimationMachineRules {
  /// Presentation plan for a state: which clip to play and whether it loops.
  public struct Play {
    /// Animation clip name as authored in `SpriteFrames`.
    let clip: String
    /// Whether the clip should loop while the state is active.
    let loop: Bool

    public init(clip: String, loop: Bool) {
      self.clip = clip
      self.loop = loop
    }
  }

  /// Mapping from **state name -> play plan**.
  public let stateToAnim: [String: Play]

  /// Mapping from clip name -> next state to enter after that clip finishes.
  ///
  /// Use this for non-looping clips like `hurt`, `land`, or one-shot attacks.
  public let animToState: [String: String]

  public init(@AnimRuleBuilder _ content: () -> [AnimRuleEntry]) {
    var stateToAnimMap: [String: Play] = [:]
    var animToStateMap: [String: String] = [:]

    for entry in content() {
      switch entry {
      case let .when(state, play): stateToAnimMap[state] = play
      case let .onFinish(clip, state): animToStateMap[clip] = state
      }
    }

    stateToAnim = stateToAnimMap
    animToState = animToStateMap
  }
}

public enum AnimRuleEntry {
  /// Bind a gameplay state to a clip to play while in that state.
  case when(state: String, play: AnimationMachineRules.Play)
  /// Bind a clip to a state to enter when the clip finishes.
  case onFinish(clip: String, state: String)
}

@_documentation(visibility: private)
@resultBuilder
public enum AnimRuleBuilder {
  public static func buildBlock(_ parts: [AnimRuleEntry]...) -> [AnimRuleEntry] { parts.flatMap { $0 } }
  public static func buildExpression(_ e: AnimRuleEntry) -> [AnimRuleEntry] { [e] }
  public static func buildOptional(_ e: [AnimRuleEntry]?) -> [AnimRuleEntry] { e ?? [] }
  public static func buildEither(first: [AnimRuleEntry]) -> [AnimRuleEntry] { first }
  public static func buildEither(second: [AnimRuleEntry]) -> [AnimRuleEntry] { second }
  public static func buildArray(_ arr: [[AnimRuleEntry]]) -> [AnimRuleEntry] { arr.flatMap { $0 } }
}

/// Declares that a gameplay state should play the given clip while active.
///
/// - Parameters:
///   - state: Gameplay state name (e.g. `"Idle"`).
///   - clip: Animation clip name (e.g. `"idle"`).
///   - loop: Whether the clip should loop while in `state` (default `true`).
///
/// ### Example
/// ```swift
/// When("Attack", play: "kick", loop: false)
/// ```
@inlinable public func When(_ state: String, play clip: String, loop: Bool = true) -> AnimRuleEntry {
  .when(state: state, play: .init(clip: clip, loop: loop))
}

/// Declares that when a clip finishes, the state machine should enter state.
///
/// - Parameters:
///   - clip: Animation clip name (e.g. `"hurt"`).
///   - state: Destination gameplay state name (e.g. `"Idle"`).
///
/// ### Example
/// ```swift
/// OnFinish("hurt", go: "Idle")
/// ```
@inlinable public func OnFinish(_ clip: String, go state: String) -> AnimRuleEntry {
  .onFinish(clip: clip, state: state)
}

// MARK: - Enum conveniences

/// Enum-friendly overload of ``When(_:play:loop:)`` where both inputs are `RawRepresentable`
/// with `String` raw values (e.g. strongly typed state/clip enums).
///
/// - Parameters:
///   - state: Gameplay state enum value.
///   - clip: Animation clip enum value.
///   - loop: Whether the clip loops while in `state`.
///
/// ### Example
/// ```swift
/// enum GState: String { case idle, move, attack, hurt }
/// enum AClip: String  { case idle, move, kick, hurt }
///
/// When(GState.attack, play: AClip.kick, loop: false)
/// ```
@inlinable public func When<S: RawRepresentable, C: RawRepresentable>(_ state: S, play clip: C, loop: Bool = true) -> AnimRuleEntry
  where S.RawValue == String, C.RawValue == String
{
  When(state.rawValue, play: clip.rawValue, loop: loop)
}

/// Enum-friendly overload of ``OnFinish(_:go:)`` where both inputs are `RawRepresentable`
/// with `String` raw values.
///
/// - Parameters:
///   - clip: Animation clip enum value.
///   - state: Destination gameplay state enum value.
///
/// ### Example
/// ```swift
/// OnFinish(AClip.hurt, go: GState.idle)
/// ```
@inlinable public func OnFinish<C: RawRepresentable, S: RawRepresentable>(_ clip: C, go state: S) -> AnimRuleEntry
  where C.RawValue == String, S.RawValue == String
{
  OnFinish(clip.rawValue, go: state.rawValue)
}

/// Wires a `StateMachine` to an `AnimatedSprite2D` using ``AnimationMachineRules``.
///
/// The stateAnimator:
/// - Plays the mapped clip whenever the **gameplay state** changes.
/// - Listens for `animationFinished` and, if a rule exists, **transitions** the state
///   machine to the configured next state.
///
/// This keeps the animation policy **outside** of gameplay logic and avoids direct
/// calls to `sprite.play(...)` inside your states.
///
/// - Important: `sprite` is held `unowned`; it **must** outlive the stateAnimator.
/// - Important: This assigns `machine.onChange` (overwriting any previous value).
///   Chain your own handler if you need both:
///   ```swift
///   let prev = machine.onChange
///   machine.onChange = { from, to in prev?(from, to); /* stateAnimator logic */ }
///   ```
///
/// ### Usage
/// ```swift
/// let rules = AnimationMachineRules {
///   When("Idle", play: "idle")
///   When("Hurt", play: "hurt", loop: false)
///   OnFinish("hurt", go: "Idle")
/// }
///
/// let stateAnimator = AnimationMachine(machine: machine, sprite: sprite, rules: rules)
/// stateAnimator.activate()
/// ```
public final class AnimationMachine {
  private let machine: StateMachine
  private unowned let sprite: AnimatedSprite2D
  private let rules: AnimationMachineRules
  private var currentClip = ""
  private var activated = false

  /// Creates a stateAnimator.
  /// - Parameters:
  ///   - machine: The gameplay state machine to observe and drive.
  ///   - sprite: The animated sprite to control. Must outlive the stateAnimator.
  ///   - rules: Declarative animation rules.
  public init(machine: StateMachine, sprite: AnimatedSprite2D, rules: AnimationMachineRules) {
    self.machine = machine
    self.sprite = sprite
    self.rules = rules
  }

  /// Connects the stateAnimator:
  /// - Sets `machine.onChange` to play the clip for the new state.
  /// - Connects `sprite.animationFinished` to apply any `OnFinish` rules.
  ///
  /// Safe to call once per stateAnimator. Calling multiple times will stack additional
  /// `animationFinished` connections on the sprite.
  public func activate() {
    if activated { return }
    activated = true

    let prev = machine.onChange

    machine.onChange = { [weak self] old, new in
      prev?(old, new)

      guard let self else { return }
      guard let plan = self.rules.stateToAnim[new] else {
        GD.print("⚠️ No animation rule for state:", new); return
      }

      self.currentClip = plan.clip
      self.sprite.spriteFrames?.setAnimationLoop(anim: StringName(plan.clip), loop: plan.loop)
      self.sprite.play(name: StringName(plan.clip))
    }

    _ = sprite.animationFinished.connect { [weak self] in
      guard let self else { return }

      let finished = self.currentClip.isEmpty ? String(self.sprite.animation) : self.currentClip
      if let next = self.rules.animToState[finished] { self.machine.transition(to: next) }
    }
  }
}
