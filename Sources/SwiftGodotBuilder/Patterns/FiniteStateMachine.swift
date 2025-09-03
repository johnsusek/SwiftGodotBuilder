import Foundation

/// A bundle of lifecycle callbacks for a single state in ``StateMachine``.
///
/// Each callback is optional:
/// - ``onEnter`` runs after a state becomes active (via ``StateMachine/start(in:)`` or ``StateMachine/transition(to:)``).
/// - ``onExit`` runs before the state is deactivated during a transition.
/// - ``onUpdate`` runs every tick while the state is active, with `delta` (seconds) you pass to ``StateMachine/update(delta:)``.
///
/// The state object is a lightweight container; the machine owns the control flow.
///
/// ### Example
/// ```swift
/// let idle = StateMachineState(
///   onEnter: { print("idle: enter") },
///   onUpdate: { dt in /* wait */ },
///   onExit: { print("idle: exit") }
/// )
/// ```
public struct StateMachineState {
  /// Called when the state becomes active.
  public var onEnter: (() -> Void)?

  /// Called right before leaving this state.
  public var onExit: (() -> Void)?

  /// Called every update tick while this state is active.
  /// - Parameter delta: Elapsed time in seconds since the last update.
  public var onUpdate: ((Double) -> Void)?

  /// Creates a state with optional lifecycle callbacks.
  /// - Parameters:
  ///   - onEnter: Invoked after the state becomes active.
  ///   - onExit: Invoked before the state is deactivated.
  ///   - onUpdate: Invoked each frame while active, receiving `delta` seconds.
  public init(onEnter: (() -> Void)? = nil,
              onExit: (() -> Void)? = nil,
              onUpdate: ((Double) -> Void)? = nil)
  {
    self.onEnter = onEnter
    self.onExit = onExit
    self.onUpdate = onUpdate
  }
}

/// A minimal, string-keyed finite state machine with enter/exit/update hooks.
///
/// States are registered by name via ``add(_:_:)``. Activate the first state
/// with ``start(in:)``; subsequent changes use ``transition(to:)``. Drive
/// per-frame behavior by calling ``update(delta:)``.
///
/// - Important: The machine is inert until ``start(in:)`` is called.
/// - Important: This type is not thread-safe. Mutate and update from one thread.
/// - Note: Transitions to the current state are ignored (no-ops).
/// - Note: ``start(in:)`` calls **only** the destination state's `onEnter`.
///   ``transition(to:)`` calls `old.onExit`, then the machine-level ``onChange``,
///   then `new.onEnter`, in that order.
///
/// ### Callback Ordering
/// For `transition(from: A, to: B)`:
/// 1. `A.onExit()`
/// 2. `onChange("A", "B")`
/// 3. `B.onEnter()`
///
/// During each ``update(delta:)``, only the **current** state's `onUpdate(delta)`
/// is invoked.
///
/// ### Usage
/// ```swift
/// let sm = StateMachine()
/// sm.add("Idle", StateMachineState(onEnter: { print("Idle") }))
/// sm.add("Run",  StateMachineState(onUpdate: { dt in /* move */ }))
/// sm.onChange = { from, to in print("↦ \(from) → \(to)") }
///
/// sm.start(in: "Idle")
/// sm.transition(to: "Run")
/// sm.update(delta: 1/60)
/// ```
public final class StateMachine {
  /// Registered states keyed by name. Adding with an existing name replaces it.
  private var states: [String: StateMachineState] = [:]

  /// The name of the currently active state, or `""` if not started.
  public private(set) var current: String = ""

  /// Notifies after a successful transition with `(old, new)` state names.
  public var onChange: ((String, String) -> Void)?

  /// Creates an empty state machine.
  public init() {}

  /// Registers (or replaces) a state under the given name.
  /// - Parameters:
  ///   - name: Unique state name.
  ///   - state: The state's callbacks.
  public func add(_ name: String, _ state: StateMachineState) { states[name] = state }

  /// Returns `true` if the machine is currently in the named state.
  /// - Parameter name: State name to compare.
  public func inState(_ name: String) -> Bool { current == name }

  /// Activates the initial state and calls its `onEnter`.
  ///
  /// If the name is unknown, nothing happens.
  /// - Parameter name: The state to start in.
  public func start(in name: String) {
    guard states[name] != nil else { return }
    current = name
    states[name]?.onEnter?()
  }

  /// Transitions to another state.
  ///
  /// If `name` equals the current state, or the target is unknown, this is a no-op.
  /// On success, the callbacks fire in this order:
  /// `old.onExit` → ``onChange``(old,new) → `new.onEnter`.
  ///
  /// - Parameter name: Destination state.
  public func transition(to name: String) {
    if name == current { return }
    guard let next = states[name] else { return }
    let old = current
    states[old]?.onExit?()
    current = name
    onChange?(old, name)
    next.onEnter?()
  }

  /// Invokes the current state's `onUpdate(delta)`, if any.
  ///
  /// - Parameter delta: Elapsed time in seconds since the last update.
  /// - Note: If the machine has not been started, this is a no-op.
  public func update(delta: Double) { states[current]?.onUpdate?(delta) }
}
