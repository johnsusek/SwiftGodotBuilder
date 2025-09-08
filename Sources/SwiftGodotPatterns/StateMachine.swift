import Foundation

/// A string-keyed finite state machine with enter/exit/update hooks.
///
/// States are registered by name via `add(_:_:)`. Activate the first state
/// with `start(in:)`; subsequent changes use `transition(to:)`. Drive
/// per-frame behavior by calling `update(delta:)`.
///
/// - Important: The machine is inert until `start(in String:)` is called.
/// - Note: Transitions to the current state are ignored (no-ops).
/// - Note: `start(in String:)` calls **only** the destination state's `onEnter`.
///   `transition(to:)` calls `old.onExit`, then the machine-level `onChange`,
///   then `new.onEnter`, in that order.
///
/// ### Callback Ordering
/// For `transition(from: A, to: B)`:
/// 1. `A.onExit()`
/// 2. `onChange("A", "B")`
/// 3. `B.onEnter()`
///
/// ### Usage
/// ```swift
/// enum Mode: String { case idle, move, attack }
///
/// let sm = StateMachine()
///
/// sm.add(Mode.idle.rawValue, .init(
///   onEnter: { print("idle enter") },
///   onUpdate: { dt in /* ... */ }
/// ))
///
/// sm.add(Mode.move.rawValue, .init(onEnter: { print("start moving") }))
/// sm.add(Mode.attack.rawValue, .init(onExit: { print("attack done") }))
///
/// sm.setOnChange(Mode.self) { from, to in
///   print("changed from \(from) to \(to)")
/// }
///
/// sm.start(in: Mode.idle.rawValue)
/// sm.transition(to: Mode.move.rawValue)
/// sm.update(delta: 1 / 60)
/// ```
///
/// ### Typed API (String-backed enums)
/// Prefer the typed helpers in the extension when your states are a `RawRepresentable`
/// enum with `String` raw values. See the ``StateMachine/setOnChange(_:_:)``
/// overloads and typed `add/start/transition/inState/current(as:)`.
public final class StateMachine {
  /// Registry of all known states keyed by name.
  private var states: [String: StateMachine.State] = [:]

  /// Current state's name. Empty string when the machine hasn't started.
  public private(set) var current: String = ""

  /// Optional observer invoked on every successful transition.
  ///
  /// - Parameters:
  ///   - from: The previous state's name.
  ///   - to: The new state's name.
  public var onChange: ((String, String) -> Void)?

  /// Creates an empty state machine.
  public init() {}

  /// Registers (or replaces) a state under a given name.
  ///
  /// - Parameters:
  ///   - name: Unique identifier for the state.
  ///   - state: Callbacks to run on enter/update/exit.
  public func add(_ name: String, _ state: StateMachine.State) { states[name] = state }

  /// Returns `true` if the machine's current state matches `name`.
  ///
  /// - Parameter name: State name to test against the current state.
  /// - Returns: `true` when `current == name`.
  public func inState(_ name: String) -> Bool { current == name }

  /// Starts the machine in the specified state.
  ///
  /// - Important: No `onExit` or `onChange` is fired during start.
  /// - Parameter name: State to become current. If it doesn't exist, this is a no-op.
  public func start(in name: String) {
    guard states[name] != nil else { return }
    current = name
    states[name]?.onEnter?()
  }

  /// Transitions from the current state to `name`.
  ///
  /// - Important: If `name == current`, this is a no-op.
  /// - Parameter name: Destination state. If it doesn't exist, this is a no-op.
  ///
  /// The ordering of callbacks is:
  /// 1. `old.onExit`
  /// 2. ``onChange``
  /// 3. `new.onEnter`
  public func transition(to name: String) {
    if name == current { return }
    guard let next = states[name] else { return }
    let old = current
    states[old]?.onExit?()
    current = name
    onChange?(old, name)
    next.onEnter?()
  }

  /// Invokes the `onUpdate` callback of the **current** state, if present.
  ///
  /// - Parameter delta: Time step (seconds).
  public func update(delta: Double) { states[current]?.onUpdate?(delta) }

  /// Container of callbacks for a single state.
  ///
  /// Provide any combination of `onEnter`, `onUpdate`, and `onExit`. Omitted
  /// handlers are simply not called.
  public struct State {
    /// Called when the machine enters this state (after `onExit` of the previous state).
    public var onEnter: (() -> Void)?

    /// Called each update tick while this state is current.
    ///
    /// - Parameter delta: Time step (seconds).
    public var onUpdate: ((Double) -> Void)?

    /// Called just before leaving this state.
    public var onExit: (() -> Void)?

    /// Creates a state with optional lifecycle callbacks.
    ///
    /// - Parameters:
    ///   - onEnter: Invoked when entering the state.
    ///   - onUpdate: Invoked on each update while in the state.
    ///   - onExit: Invoked when exiting the state.
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
  /// Registers (or replaces) a state using a typed `RawRepresentable` key.
  ///
  /// - Parameters:
  ///   - name: Enum value whose `rawValue` is used as the state name.
  ///   - state: Callbacks to run on enter/update/exit.
  @inlinable
  func add<S: RawRepresentable>(_ name: S, _ state: State) where S.RawValue == String {
    add(name.rawValue, state)
  }

  /// Starts the machine in the specified typed state.
  ///
  /// - Parameter name: Enum whose `rawValue` identifies the target state.
  @inlinable
  func start<S: RawRepresentable>(in name: S) where S.RawValue == String {
    start(in: name.rawValue)
  }

  /// Transitions to the specified typed state.
  ///
  /// - Parameter name: Enum whose `rawValue` identifies the destination state.
  @inlinable
  func transition<S: RawRepresentable>(to name: S) where S.RawValue == String {
    transition(to: name.rawValue)
  }

  /// Returns `true` if the machine's current state matches the typed value.
  ///
  /// - Parameter name: Enum to test against `current`.
  /// - Returns: `true` when `current == name.rawValue`.
  @inlinable
  func inState<S: RawRepresentable>(_ name: S) -> Bool where S.RawValue == String {
    inState(name.rawValue)
  }

  /// Attempts to view the current state as a typed enum.
  ///
  /// - Parameter _: The enum type to construct.
  /// - Returns: The enum case whose `rawValue` equals `current`, or `nil`.
  @inlinable
  func current<S: RawRepresentable>(as _: S.Type) -> S? where S.RawValue == String {
    S(rawValue: current)
  }

  // MARK: - Change observers (typed and untyped)

  /// Sets a **typed** `onChange` handler, replacing any existing one.
  ///
  /// - Parameters:
  ///   - _: Enum type implementing `RawRepresentable` with `String` raw value.
  ///   - handler: Invoked for every successful transition.
  ///
  /// - Important: This **replaces** the machine's ``onChange``. Use
  ///   ``addChangeObserver(_:_:)`` to append without replacing.
  @inlinable
  func setOnChange<S: RawRepresentable>(_: S.Type, _ handler: @escaping (S, S) -> Void)
    where S.RawValue == String
  {
    onChange = { from, to in
      guard let f = S(rawValue: from), let t = S(rawValue: to) else { return }
      handler(f, t)
    }
  }

  /// Appends an additional (untyped) change observer.
  ///
  /// - Parameter observer: Called with `(from, to)` after `onExit` and before `onEnter`.
  @inlinable
  func addChangeObserver(_ observer: @escaping (String, String) -> Void) {
    let prev = onChange
    onChange = { from, to in prev?(from, to); observer(from, to) }
  }

  /// Appends an additional **typed** change observer.
  ///
  /// - Parameters:
  ///   - _: Enum type implementing `RawRepresentable` with `String` raw value.
  ///   - observer: Called with typed `(from, to)` after `onExit` and before `onEnter`.
  @inlinable
  func addChangeObserver<S: RawRepresentable>(_: S.Type, _ observer: @escaping (S, S) -> Void)
    where S.RawValue == String
  {
    addChangeObserver { from, to in
      guard let f = S(rawValue: from), let t = S(rawValue: to) else { return }
      observer(f, t)
    }
  }
}
