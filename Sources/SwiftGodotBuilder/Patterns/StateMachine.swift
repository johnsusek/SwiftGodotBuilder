import Foundation

/// A string-keyed finite state machine with enter/exit/update hooks.
///
/// States are registered by name via ``add(_:_:)``. Activate the first state
/// with ``start(in:)``; subsequent changes use ``transition(to:)``. Drive
/// per-frame behavior by calling ``update(delta:)``.
///
/// - Important: The machine is inert until ``start(in:)`` is called.
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
/// sm.add("Idle", StateMachine.State(onEnter: { print("Idle") }))
/// sm.add("Run",  StateMachine.State(onUpdate: { dt in /* move */ }))
/// sm.onChange = { from, to in print("↦ \(from) -> \(to)") }
///
/// sm.start(in: "Idle")
/// sm.transition(to: "Run")
/// sm.update(delta: 1/60)
/// ```
public final class StateMachine {
  /// Registered states keyed by name. Adding with an existing name replaces it.
  private var states: [String: StateMachine.State] = [:]

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
  public func add(_ name: String, _ state: StateMachine.State) { states[name] = state }

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
  /// `old.onExit` -> ``onChange``(old,new) -> `new.onEnter`.
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

  /// A bundle of lifecycle callbacks for a single state in ``StateMachine``.
  ///
  /// Each callback is optional:
  /// - ``onEnter`` runs after a state becomes active (via ``StateMachine/start(in:)`` or ``StateMachine/transition(to:)``).
  /// - ``onUpdate`` runs every tick while the state is active, with `delta` (seconds) you pass to ``StateMachine/update(delta:)``.
  /// - ``onExit`` runs before the state is deactivated during a transition.
  ///
  /// The state object is a lightweight container; the machine owns the control flow.
  ///
  /// ### Example
  /// ```swift
  /// let idle = StateMachine.State(
  ///   onEnter: { print("idle: enter") },
  ///   onUpdate: { dt in /* wait */ },
  ///   onExit: { print("idle: exit") }
  /// )
  /// ```
  public struct State {
    /// Called when the state becomes active.
    public var onEnter: (() -> Void)?

    /// Called every update tick while this state is active.
    /// - Parameter delta: Elapsed time in seconds since the last update.
    public var onUpdate: ((Double) -> Void)?

    /// Called right before leaving this state.
    public var onExit: (() -> Void)?

    /// Creates a state with optional lifecycle callbacks.
    /// - Parameters:
    ///   - onEnter: Invoked after the state becomes active.
    ///   - onExit: Invoked before the state is deactivated.
    ///   - onUpdate: Invoked each frame while active, receiving `delta` seconds.
    public init(onEnter: (() -> Void)? = nil,
                onUpdate: ((Double) -> Void)? = nil,
                onExit: (() -> Void)? = nil)
    {
      self.onEnter = onEnter
      self.onUpdate = onUpdate
      self.onExit = onExit
    }
  }
}

// MARK: - Typed (String-backed) enums

public extension StateMachine {
  /// Registers (or replaces) a state using a String-backed enum.
  @inlinable
  func add<S: RawRepresentable>(_ name: S, _ state: State) where S.RawValue == String {
    add(name.rawValue, state)
  }

  /// Starts the machine in a typed state.
  @inlinable
  func start<S: RawRepresentable>(in name: S) where S.RawValue == String {
    start(in: name.rawValue)
  }

  /// Transitions to a typed state (no-op if unknown or identical to current).
  @inlinable
  func transition<S: RawRepresentable>(to name: S) where S.RawValue == String {
    transition(to: name.rawValue)
  }

  /// Returns true iff the machine is currently in the typed state.
  @inlinable
  func inState<S: RawRepresentable>(_ name: S) -> Bool where S.RawValue == String {
    inState(name.rawValue)
  }

  /// Attempts to view `current` as the enum type.
  @inlinable
  func current<S: RawRepresentable>(as _: S.Type) -> S? where S.RawValue == String {
    S(rawValue: current)
  }

  // MARK: - Change observers (typed and untyped)

  /// Replaces `onChange` with a typed handler.
  @inlinable
  func setOnChange<S: RawRepresentable>(_ type: S.Type, _ handler: @escaping (S, S) -> Void)
  where S.RawValue == String {
    onChange = { from, to in
      guard let f = S(rawValue: from), let t = S(rawValue: to) else { return }
      handler(f, t)
    }
  }

  /// Chains an additional untyped change observer (keeps any existing one).
  @inlinable
  func addChangeObserver(_ observer: @escaping (String, String) -> Void) {
    let prev = onChange
    onChange = { from, to in prev?(from, to); observer(from, to) }
  }

  /// Chains an additional typed change observer (keeps any existing one).
  @inlinable
  func addChangeObserver<S: RawRepresentable>(_ type: S.Type, _ observer: @escaping (S, S) -> Void)
  where S.RawValue == String {
    addChangeObserver { from, to in
      guard let f = S(rawValue: from), let t = S(rawValue: to) else { return }
      observer(f, t)
    }
  }
}
